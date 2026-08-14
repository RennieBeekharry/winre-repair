// WR-MODULE: github-auth-js 2026.08.14-1043-ET
(function () {
    var a = WScript.Arguments;
    if (a.length < 10) WScript.Quit(91);

    var mode = String(a(0)).toLowerCase();
    var curl = a(1), nslookup = a(2), dns = a(3), work = a(4);
    var logrepo = a(5), tokenfile = a(6), report = a(7), details = a(8), clientId = a(9);

    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var shell = new ActiveXObject("WScript.Shell");
    var resultFile = work + "\\GITHUB_RESULT.txt";
    var apiVersion = "2022-11-28";

    function writeResult(status, reason, http, path) {
        var f = fso.CreateTextFile(resultFile, true);
        f.WriteLine("status=" + status);
        f.WriteLine("reason=" + reason);
        f.WriteLine("http=" + (http || ""));
        if (path) f.WriteLine("path=" + path);
        f.Close();
    }
    function q(s) { return '"' + String(s).replace(/"/g, '\\"') + '"'; }
    function readText(path) {
        if (!fso.FileExists(path)) return "";
        var f = fso.OpenTextFile(path, 1, false), s = f.ReadAll(); f.Close(); return s;
    }
    function writeText(path, text) { var f = fso.CreateTextFile(path, true); f.Write(text); f.Close(); }
    function parseJson(path) {
        var t = readText(path); if (!t) return null;
        try { return eval("(" + t + ")"); } catch (e) { return null; }
    }
    function resolveHost(host) {
        try {
            var e = shell.Exec(q(nslookup) + " " + host + " " + dns), out = "";
            while (!e.StdOut.AtEndOfStream) out += e.StdOut.ReadLine() + "\n";
            var re = /(\d{1,3}(?:\.\d{1,3}){3})/g, m, last = "";
            while ((m = re.exec(out)) !== null) if (m[1] != dns) last = m[1];
            return last;
        } catch (e2) { return ""; }
    }
    function runCurl(host, args, bodyFile, statusFile) {
        var ip = resolveHost(host);
        var cmd = q(curl) + " --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 180 ";
        if (ip) cmd += "--resolve " + q(host + ":443:" + ip) + " ";
        cmd += args;
        if (bodyFile) cmd += " -o " + q(bodyFile);
        if (statusFile) cmd += " -w " + q("%{http_code}") + " > " + q(statusFile);
        return shell.Run("cmd.exe /d /c " + q(cmd), 0, true);
    }
    function httpCode(statusFile) { var s = readText(statusFile).replace(/\s+/g, ""); return s || "000"; }
    function utf8Bytes(s) {
        var b = [], i, c, c2, cp;
        for (i = 0; i < s.length; i++) {
            c = s.charCodeAt(i);
            if (c < 0x80) b.push(c);
            else if (c < 0x800) b.push(0xC0 | (c >> 6), 0x80 | (c & 0x3F));
            else if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.length) {
                c2 = s.charCodeAt(++i); cp = 0x10000 + ((c - 0xD800) << 10) + (c2 - 0xDC00);
                b.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
            } else b.push(0xE0 | (c >> 12), 0x80 | ((c >> 6) & 0x3F), 0x80 | (c & 0x3F));
        }
        return b;
    }
    function base64Utf8(s) {
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        var b = utf8Bytes(s), out = "", i, a1, a2, a3, n;
        for (i = 0; i < b.length; i += 3) {
            a1 = b[i]; a2 = (i + 1 < b.length) ? b[i + 1] : -1; a3 = (i + 2 < b.length) ? b[i + 2] : -1;
            n = (a1 << 16) | ((a2 < 0 ? 0 : a2) << 8) | (a3 < 0 ? 0 : a3);
            out += chars.charAt((n >> 18) & 63) + chars.charAt((n >> 12) & 63);
            out += a2 < 0 ? "=" : chars.charAt((n >> 6) & 63);
            out += a3 < 0 ? "=" : chars.charAt(n & 63);
        }
        return out;
    }
    function uploadWithToken(token, label) {
        var text = "PRIVATE AI RECOVERY RUN REPORT\r\n==================================\r\n" + readText(report);
        if (details && fso.FileExists(details)) text += "\r\n--- RUN_DETAILS ---\r\n" + readText(details);
        var safeLabel = String(label || "run").replace(/[^A-Za-z0-9._-]/g, "_");
        var path = "reports/inbox/" + safeLabel + "-" + (new Date()).getTime() + ".txt";
        var req = work + "\\github-upload-request.json", resp = work + "\\github-upload-response.json", stat = work + "\\github-upload-status.txt";
        writeText(req, '{"message":"AI Recovery report","content":"' + base64Utf8(text) + '"}');
        var host = "api.github.com", url = "https://" + host + "/repos/" + logrepo + "/contents/" + path;
        var args = "-X PUT -H " + q("Accept: application/vnd.github+json") + " -H " + q("Authorization: Bearer " + token) +
                   " -H " + q("X-GitHub-Api-Version: " + apiVersion) + " -H " + q("Content-Type: application/json") +
                   " --data-binary " + q("@" + req) + " " + q(url);
        runCurl(host, args, resp, stat);
        var http = httpCode(stat);
        if (http == "201" || http == "200") { writeResult("PASS", "Private report uploaded.", http, path); return 0; }
        var reason = "GitHub upload failed.";
        if (http == "401") reason = "Saved authorization is invalid, expired, or revoked.";
        else if (http == "403") reason = "Authorization exists but GitHub forbids the repository write.";
        else if (http == "404") reason = "Authorized account cannot access the configured private log repository.";
        else if (http == "429") reason = "GitHub rate limit reached.";
        else if (http == "000") reason = "No GitHub API response; network, DNS, or TLS failed.";
        else if (http.charAt(0) == "5") reason = "Temporary GitHub server error.";
        writeResult("FAIL", reason, http, ""); return 90;
    }
    function authorize() {
        if (!/^[A-Za-z0-9]+$/.test(String(clientId))) { writeResult("FAIL", "OAuth client ID is not configured.", "LOCAL", ""); return 91; }
        if (fso.FileExists(tokenfile)) {
            var existing = readText(tokenfile).replace(/\s+/g, "");
            if (existing) {
                var erc = uploadWithToken(existing, "bootstrap-existing");
                if (erc == 0) return 0;
                try { fso.DeleteFile(tokenfile, true); } catch (ignore) {}
            }
        }
        var host = "github.com", deviceResp = work + "\\github-device.json", deviceStat = work + "\\github-device-status.txt";
        var deviceArgs = "-X POST -H " + q("Accept: application/json") + " -H " + q("Content-Type: application/x-www-form-urlencoded") +
                         " --data " + q("client_id=" + clientId + "&scope=repo") + " " + q("https://github.com/login/device/code");
        runCurl(host, deviceArgs, deviceResp, deviceStat);
        var dh = httpCode(deviceStat), d = parseJson(deviceResp);
        if (dh != "200" || !d || !d.device_code || !d.user_code) { writeResult("FAIL", "Could not start GitHub device authorization.", dh, ""); return 90; }
        WScript.Echo("================================================================");
        WScript.Echo("GITHUB DEVICE AUTHORIZATION");
        WScript.Echo("================================================================");
        WScript.Echo("On your phone, open:");
        WScript.Echo("  " + (d.verification_uri || "https://github.com/login/device"));
        WScript.Echo("");
        WScript.Echo("Enter this short one-time code:");
        WScript.Echo("");
        WScript.Echo("                 " + d.user_code);
        WScript.Echo("");
        WScript.Echo("The PC waits automatically after you approve it.");
        WScript.Echo("================================================================");
        var interval = Number(d.interval || 5), deadline = (new Date()).getTime() + Number(d.expires_in || 900) * 1000;
        var tokenResp = work + "\\github-token.json", tokenStat = work + "\\github-token-status.txt";
        while ((new Date()).getTime() < deadline) {
            WScript.Sleep(interval * 1000);
            var tokenArgs = "-X POST -H " + q("Accept: application/json") + " -H " + q("Content-Type: application/x-www-form-urlencoded") +
                            " --data " + q("client_id=" + clientId + "&device_code=" + d.device_code + "&grant_type=urn:ietf:params:oauth:grant-type:device_code") +
                            " " + q("https://github.com/login/oauth/access_token");
            runCurl(host, tokenArgs, tokenResp, tokenStat);
            var th = httpCode(tokenStat), t = parseJson(tokenResp);
            if (th != "200" || !t) continue;
            if (t.access_token) {
                var urc = uploadWithToken(t.access_token, "bootstrap-device");
                if (urc != 0) return urc;
                writeText(tokenfile, t.access_token + "\r\n");
                shell.Run("cmd.exe /d /c attrib +h +s " + q(tokenfile), 0, true);
                return 0;
            }
            if (t.error == "authorization_pending") continue;
            if (t.error == "slow_down") { interval += 5; continue; }
            if (t.error == "access_denied") { writeResult("FAIL", "GitHub device authorization was denied.", th, ""); return 90; }
            if (t.error == "expired_token") { writeResult("FAIL", "GitHub one-time device code expired; start authorization again.", th, ""); return 90; }
            if (t.error) { writeResult("FAIL", "GitHub device authorization error: " + t.error, th, ""); return 90; }
        }
        writeResult("FAIL", "GitHub one-time device code expired; start authorization again.", "TIMEOUT", ""); return 90;
    }
    if (mode == "authorize") WScript.Quit(authorize());
    if (mode == "upload") {
        if (!fso.FileExists(tokenfile)) { writeResult("FAIL", "Private reporting is not authorized yet.", "LOCAL", ""); WScript.Quit(90); }
        var tok = readText(tokenfile).replace(/\s+/g, "");
        if (!tok) { writeResult("FAIL", "Saved authorization file is empty.", "LOCAL", ""); WScript.Quit(90); }
        WScript.Quit(uploadWithToken(tok, "run"));
    }
    writeResult("FAIL", "Unknown GitHub authorization module mode.", "LOCAL", ""); WScript.Quit(91);
})();
