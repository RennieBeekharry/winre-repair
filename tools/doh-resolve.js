// WR-MODULE: doh-resolve-js 2026.08.14-1608-ET
(function () {
    var a = WScript.Arguments;
    if (a.length < 2) WScript.Quit(64);
    var curl = String(a(0));
    var host = String(a(1));
    var shell = new ActiveXObject("WScript.Shell");
    var dohHost = "cloudflare-dns.com";
    var dohIps = ["1.1.1.1", "1.0.0.1"];

    function q(s) { return '"' + String(s).replace(/"/g, '\\"') + '"'; }
    function validIpv4(s) {
        var p = String(s || "").split("."), i, n;
        if (p.length !== 4) return false;
        for (i = 0; i < 4; i++) {
            if (!/^\d{1,3}$/.test(p[i])) return false;
            n = Number(p[i]);
            if (n < 0 || n > 255) return false;
        }
        return true;
    }
    function parseJson(s) { try { return eval("(" + s + ")"); } catch (e) { return null; } }

    for (var d = 0; d < dohIps.length; d++) {
        try {
            var cmd = q(curl) +
                " --ssl-no-revoke --silent --show-error --fail --connect-timeout 10 --max-time 45" +
                " --resolve " + q(dohHost + ":443:" + dohIps[d]) +
                " -H " + q("Accept: application/dns-json") +
                " " + q("https://" + dohHost + "/dns-query?name=" + host + "&type=A");
            var e = shell.Exec(cmd), out = "", err = "";
            while (e.Status === 0) WScript.Sleep(100);
            if (!e.StdOut.AtEndOfStream) out = e.StdOut.ReadAll();
            if (!e.StdErr.AtEndOfStream) err = e.StdErr.ReadAll();
            if (e.ExitCode !== 0) continue;
            var root = parseJson(out);
            if (!root || Number(root.Status) !== 0 || !root.Answer) continue;
            var found = [], i, item, ip;
            for (i = 0; i < root.Answer.length; i++) {
                item = root.Answer[i];
                if (Number(item.type) !== 1) continue;
                ip = String(item.data || "").replace(/^\s+|\s+$/g, "");
                if (validIpv4(ip)) found.push(ip);
            }
            if (found.length) {
                WScript.Echo("Name: " + host);
                for (i = 0; i < found.length; i++) WScript.Echo("Address: " + found[i]);
                WScript.Quit(0);
            }
        } catch (ex) {}
    }
    WScript.Quit(1);
})();
