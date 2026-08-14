// WR-MODULE: agent-core-js 2026.08.14-1026-ET
// Parses a private GitHub command queue. It NEVER executes shell text.
(function () {
    var a = WScript.Arguments;
    if (a.length < 7) WScript.Quit(91);
    var mode = String(a(0)).toLowerCase();
    var curl = a(1), work = a(2), configPath = a(3), tokenPath = a(4), agentId = a(5), pendingPath = a(6);
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var shell = new ActiveXObject("WScript.Shell");
    var apiVersion = "2022-11-28";

    function readText(p) {
        if (!fso.FileExists(p)) return "";
        var f = fso.OpenTextFile(p, 1, false), s = f.ReadAll(); f.Close(); return s;
    }
    function writeText(p, s) { var f = fso.CreateTextFile(p, true); f.Write(s); f.Close(); }
    function q(s) { return '"' + String(s).replace(/"/g, '\\"') + '"'; }
    function parseConfig() {
        var cfg = {}, lines = readText(configPath).split(/\r?\n/), i, n;
        for (i = 0; i < lines.length; i++) {
            n = lines[i].indexOf("=");
            if (n > 0) cfg[lines[i].substr(0,n).replace(/^\s+|\s+$/g,"").toUpperCase()] = lines[i].substr(n+1).replace(/^\s+|\s+$/g,"");
        }
        return cfg;
    }
    function parseJson(s) { try { return eval("(" + s + ")"); } catch (e) { return null; } }
    function validRepo(s) { return /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(String(s)); }
    function validPath(s) { return /^[A-Za-z0-9_.\/-]+$/.test(String(s)); }
    function validAgent(s) { return s === "*" || /^[A-Z0-9_-]{6,80}$/.test(String(s)); }
    function validId(s) { return /^\d{1,15}$/.test(String(s)); }
    function validRef(s) { return /^[0-9a-fA-F]{40}$/.test(String(s)); }
    function validSha(s) { return /^[0-9a-fA-F]{64}$/.test(String(s)); }
    function writeState(status, reason) {
        writeText(work + "\\AGENT_STATE.txt", "status=" + status + "\r\nreason=" + reason + "\r\nagent_id=" + agentId + "\r\n");
    }
    function curlGet(url, token, out, status) {
        var cmd = q(curl) + " --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120" +
                  " -H " + q("Accept: application/vnd.github.raw+json") +
                  " -H " + q("Authorization: Bearer " + token) +
                  " -H " + q("X-GitHub-Api-Version: " + apiVersion) +
                  " -o " + q(out) + " -w " + q("%{http_code}") + " " + q(url) + " > " + q(status);
        return shell.Run("cmd.exe /d /c " + q(cmd), 0, true);
    }
    function numericState(p) {
        var s = readText(p).replace(/\s+/g,"");
        return validId(s) ? Number(s) : 0;
    }
    function highestHandledId() {
        var last = numericState(work + "\\agent\\last-command-id.txt");
        var inflight = numericState(work + "\\agent\\inflight-command-id.txt");
        return inflight > last ? inflight : last;
    }
    function poll() {
        var cfg = parseConfig(), token = readText(tokenPath).replace(/\s+/g, "");
        if (!token) { writeState("FAIL", "Private GitHub authorization is missing."); return 90; }
        if (!validRepo(cfg.CONTROL_REPO || "")) { writeState("FAIL", "CONTROL_REPO configuration is invalid."); return 91; }
        var controlPath = cfg.CONTROL_PATH || "control/current-command.json";
        if (!validPath(controlPath)) { writeState("FAIL", "CONTROL_PATH configuration is invalid."); return 91; }
        var ref = cfg.CONTROL_REF || "main";
        if (!/^[A-Za-z0-9_.\/-]+$/.test(ref)) { writeState("FAIL", "CONTROL_REF configuration is invalid."); return 91; }
        var body = work + "\\agent\\queue.json", stat = work + "\\agent\\queue-http.txt";
        var url = "https://api.github.com/repos/" + cfg.CONTROL_REPO + "/contents/" + controlPath + "?ref=" + ref;
        curlGet(url, token, body, stat);
        var http = readText(stat).replace(/\s+/g, "") || "000";
        if (http !== "200") { writeState("WARNING", "Control queue unavailable. GitHub HTTP " + http + "."); return 40; }
        var c = parseJson(readText(body));
        if (!c) { writeState("FAIL", "Control queue JSON is invalid."); return 93; }
        if (Number(c.protocol) !== 1) { writeState("FAIL", "Unsupported command protocol."); return 93; }
        if (!validId(String(c.command_id || ""))) { writeState("FAIL", "Invalid command_id."); return 93; }
        var cid = Number(c.command_id);
        if (cid <= highestHandledId()) { writeState("IDLE", "No new command."); return 10; }
        var action = String(c.action || "").toUpperCase();
        if (action !== "RUN_NEXT" && action !== "PING" && action !== "STOP_AGENT") { writeState("FAIL", "Command action is not allowlisted."); return 94; }
        var target = String(c.target_agent || "").toUpperCase();
        if (!validAgent(target)) { writeState("FAIL", "Invalid target_agent."); return 93; }
        if (target !== "*" && target !== String(agentId).toUpperCase()) { writeState("IDLE", "Command targets another agent."); return 10; }
        var risk = String(c.risk || "").toUpperCase();
        if (risk !== "READ_ONLY" && risk !== "REPAIR_WRITE" && risk !== "DESTRUCTIVE") { writeState("FAIL", "Invalid risk classification."); return 93; }
        var now = (new Date()).getTime();
        if (c.issued_at && isNaN(Date.parse(c.issued_at))) { writeState("FAIL", "Invalid issued_at timestamp."); return 93; }
        if (c.expires_at && isNaN(Date.parse(c.expires_at))) { writeState("FAIL", "Invalid expires_at timestamp."); return 93; }
        if (c.issued_at && Date.parse(c.issued_at) > now + 300000) { writeState("FAIL", "Command is not valid yet."); return 95; }
        if (c.expires_at && Date.parse(c.expires_at) < now) { writeState("FAIL", "Command expired before execution."); return 95; }

        var lines = [];
        lines.push("WR_CMD_ID=" + String(c.command_id));
        lines.push("WR_CMD_ACTION=" + action);
        lines.push("WR_CMD_TARGET=" + target);
        lines.push("WR_CMD_RISK=" + risk);
        if (action === "RUN_NEXT") {
            var repo = String(c.repo || ""), path = String(c.path || ""), cre = String(c.ref || ""), sha = String(c.sha256 || "");
            if (!validRepo(repo) || !validPath(path) || !validRef(cre) || !validSha(sha)) { writeState("FAIL", "RUN_NEXT source metadata failed validation."); return 93; }
            lines.push("WR_CMD_REPO=" + repo);
            lines.push("WR_CMD_PATH=" + path);
            lines.push("WR_CMD_REF=" + cre.toLowerCase());
            lines.push("WR_CMD_SHA256=" + sha.toLowerCase());
        }
        writeText(pendingPath, lines.join("\r\n") + "\r\n");
        writeState("READY", "New validated command is ready for local safety evaluation.");
        return 0;
    }

    if (mode === "poll") WScript.Quit(poll());
    writeState("FAIL", "Unknown agent-core mode.");
    WScript.Quit(91);
})();
