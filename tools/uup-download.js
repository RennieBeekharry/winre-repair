// WR-MODULE: uup-download-js 2026.08.14-1535-ET
// RescueMeAI resumable UUP downloader. Downloads only into the selected media workspace.
(function () {
    var a = WScript.Arguments;
    if (a.length < 6) WScript.Quit(91);

    var curl = String(a(0));
    var certutil = String(a(1));
    var nslookup = String(a(2));
    var metaPath = String(a(3));
    var dest = String(a(4));
    var statePath = String(a(5));

    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var shell = new ActiveXObject("WScript.Shell");
    var dnsServers = ["64.71.255.204", "1.1.1.1", "8.8.8.8", "9.9.9.9"];

    function readText(p) {
        if (!fso.FileExists(p)) return "";
        var f = fso.OpenTextFile(p, 1, false), s = f.ReadAll();
        f.Close();
        return s;
    }
    function writeText(p, s) {
        var f = fso.CreateTextFile(p, true);
        f.Write(s);
        f.Close();
    }
    function appendText(p, s) {
        var f = fso.OpenTextFile(p, 8, true);
        f.Write(s);
        f.Close();
    }
    function q(s) { return '"' + String(s).replace(/"/g, '\\"') + '"'; }
    function parseJson(s) { try { return eval("(" + s + ")"); } catch (e) { return null; } }
    function hex40(s) { return /^[0-9a-fA-F]{40}$/.test(String(s || "")); }
    function validIpv4(s) {
        var p = String(s || "").replace(/\s+/g, "").split("."), i, n;
        if (p.length !== 4) return false;
        for (i = 0; i < 4; i++) {
            if (!/^\d{1,3}$/.test(p[i])) return false;
            n = Number(p[i]);
            if (n < 0 || n > 255) return false;
        }
        return true;
    }
    function safeName(s) {
        s = String(s || "");
        if (!s || s.length > 220) return false;
        if (s.indexOf("..") >= 0 || s.indexOf("\\") >= 0 || s.indexOf("/") >= 0 || s.indexOf(":") >= 0) return false;
        return /^[A-Za-z0-9 _.,+(){}\[\]-]+$/.test(s);
    }
    function urlParts(url) {
        var m = /^(https?):\/\/([^\/:]+)(?::(\d+))?(\/.*)?$/i.exec(String(url || ""));
        if (!m) return null;
        return { scheme: m[1].toLowerCase(), host: m[2].toLowerCase(), port: m[3] ? Number(m[3]) : (m[1].toLowerCase() === "https" ? 443 : 80) };
    }
    function allowedHost(h) {
        h = String(h || "").toLowerCase();
        return h === "delivery.mp.microsoft.com" ||
               /\.delivery\.mp\.microsoft\.com$/.test(h) ||
               h === "download.windowsupdate.com" ||
               /\.windowsupdate\.com$/.test(h) ||
               /\.update\.microsoft\.com$/.test(h) ||
               /\.microsoftusercontent\.com$/.test(h);
    }
    function resolveHost(host) {
        var d, cmd, e, out, re, m, found;
        for (d = 0; d < dnsServers.length; d++) {
            try {
                cmd = q(nslookup) + " " + host + " " + dnsServers[d];
                e = shell.Exec(cmd);
                out = "";
                while (!e.StdOut.AtEndOfStream) out += e.StdOut.ReadLine() + "\n";
                re = /(\d{1,3}(?:\.\d{1,3}){3})/g;
                found = "";
                while ((m = re.exec(out)) !== null) {
                    if (m[1] !== dnsServers[d] && validIpv4(m[1])) found = m[1];
                }
                if (validIpv4(found)) return found;
            } catch (ex) {}
        }
        return "";
    }
    function hashSha1(path) {
        var cmd = q(certutil) + " -hashfile " + q(path) + " SHA1", e, out = "", m;
        try {
            e = shell.Exec(cmd);
            while (!e.StdOut.AtEndOfStream) out += e.StdOut.ReadLine() + "\n";
            while (e.Status === 0) WScript.Sleep(50);
            m = /(^|[\r\n])\s*([0-9A-Fa-f]{40})\s*([\r\n]|$)/.exec(out);
            return m ? m[2].toLowerCase() : "";
        } catch (ex) { return ""; }
    }
    function gb(n) { return (Number(n) / 1073741824).toFixed(2); }
    function saveState(status, extra) {
        var s = "status=" + status + "\r\n";
        if (extra) s += extra;
        writeText(statePath, s);
    }
    function ensureFolder(p) {
        if (!fso.FolderExists(p)) fso.CreateFolder(p);
    }

    var raw = readText(metaPath);
    var root = parseJson(raw);
    if (!root || !root.response || !root.response.files) {
        saveState("FAIL", "reason=UUP metadata JSON is invalid.\r\n");
        WScript.Quit(96);
    }

    var r = root.response;
    if (String(r.build || "") !== "26100.8894" || String(r.arch || "").toLowerCase() !== "amd64") {
        saveState("FAIL", "reason=UUP metadata does not match build 26100.8894 amd64.\r\n");
        WScript.Quit(96);
    }

    ensureFolder(dest);
    var files = [], name, f, size, url, parts, total = 0, i;
    for (name in r.files) {
        if (!r.files.hasOwnProperty(name)) continue;
        f = r.files[name];
        size = Number(f.size || 0);
        url = String(f.url || "");
        parts = urlParts(url);
        if (!safeName(name) || !(size > 0) || !hex40(f.sha1) || !parts || !allowedHost(parts.host)) {
            saveState("FAIL", "reason=UUP file metadata failed validation.\r\nfile=" + String(name) + "\r\n");
            WScript.Quit(96);
        }
        files.push({name: name, size: size, sha1: String(f.sha1).toLowerCase(), url: url, host: parts.host, port: parts.port});
        total += size;
    }
    if (files.length < 5 || total < 1073741824) {
        saveState("FAIL", "reason=UUP file set is unexpectedly small.\r\n");
        WScript.Quit(96);
    }

    files.sort(function(x, y) { return x.name.toLowerCase() < y.name.toLowerCase() ? -1 : (x.name.toLowerCase() > y.name.toLowerCase() ? 1 : 0); });

    var driveName = fso.GetDriveName(dest);
    if (!driveName) {
        saveState("FAIL", "reason=Destination drive could not be determined.\r\n");
        WScript.Quit(97);
    }
    var drive = fso.GetDrive(driveName);
    var remaining = 0, existing = 0, path;
    for (i = 0; i < files.length; i++) {
        path = fso.BuildPath(dest, files[i].name);
        existing = fso.FileExists(path) ? Number(fso.GetFile(path).Size) : 0;
        if (existing > files[i].size) {
            try { fso.DeleteFile(path, true); existing = 0; } catch (ex2) {
                saveState("FAIL", "reason=An oversized partial media file could not be replaced.\r\nfile=" + files[i].name + "\r\n");
                WScript.Quit(97);
            }
        }
        if (existing === files[i].size) {
            if (hashSha1(path) !== files[i].sha1) remaining += files[i].size;
        } else {
            remaining += (files[i].size - existing);
        }
    }

    var margin = 10737418240;
    if (Number(drive.FreeSpace) < remaining + margin) {
        saveState("FAIL", "reason=Insufficient free space on REPAIRDATA.\r\nfree_bytes=" + drive.FreeSpace + "\r\nrequired_download_bytes=" + remaining + "\r\n");
        WScript.Quit(97);
    }

    var manifest = fso.BuildPath(dest, "RescueMeAI-UUP-manifest.txt");
    writeText(manifest,
        "RescueMeAI Windows recovery source\r\n" +
        "build=26100.8894\r\narch=amd64\r\nedition=core\r\nlanguage=en-us\r\n" +
        "file_count=" + files.length + "\r\ntotal_bytes=" + total + "\r\n\r\n");
    for (i = 0; i < files.length; i++) {
        appendText(manifest, files[i].sha1 + "  " + files[i].size + "  " + files[i].name + "\r\n");
    }

    WScript.Echo("");
    WScript.Echo("============================================================");
    WScript.Echo("        RESCUEMEAI - WINDOWS RECOVERY MEDIA DOWNLOAD");
    WScript.Echo("============================================================");
    WScript.Echo("Source      : Windows 11 24H2 build 26100.8894 x64");
    WScript.Echo("Edition     : Home / Core, en-US");
    WScript.Echo("Destination : " + dest);
    WScript.Echo("Files       : " + files.length);
    WScript.Echo("Download    : " + gb(remaining) + " GiB remaining");
    WScript.Echo("");
    WScript.Echo("No Windows system files, partitions, or boot settings are being changed.");
    WScript.Echo("Existing partial media files will be resumed when possible.");
    WScript.Echo("============================================================");
    WScript.Echo("");

    var completedBytes = total - remaining, rc, ip, cmd, attempt, actual;
    for (i = 0; i < files.length; i++) {
        f = files[i];
        path = fso.BuildPath(dest, f.name);

        if (fso.FileExists(path) && Number(fso.GetFile(path).Size) === f.size) {
            actual = hashSha1(path);
            if (actual === f.sha1) {
                WScript.Echo("[OK] " + (i + 1) + "/" + files.length + " already verified: " + f.name);
                continue;
            }
            try { fso.DeleteFile(path, true); } catch (ex3) {
                saveState("FAIL", "reason=Existing media file failed SHA-1 and could not be replaced.\r\nfile=" + f.name + "\r\n");
                WScript.Quit(97);
            }
        }

        ip = resolveHost(f.host);
        if (!ip) {
            saveState("FAIL", "reason=Could not resolve Microsoft download host.\r\nhost=" + f.host + "\r\nfile=" + f.name + "\r\n");
            WScript.Quit(92);
        }

        WScript.Echo("");
        WScript.Echo("Downloading " + (i + 1) + " of " + files.length + ": " + f.name);
        WScript.Echo("Overall completed before this file: " + gb(completedBytes) + " / " + gb(total) + " GiB");
        saveState("DOWNLOADING",
            "file_index=" + (i + 1) + "\r\nfile_count=" + files.length + "\r\nfile=" + f.name + "\r\n" +
            "completed_bytes=" + completedBytes + "\r\ntotal_bytes=" + total + "\r\n");

        rc = 90;
        for (attempt = 1; attempt <= 2; attempt++) {
            cmd = q(curl) +
                " --ssl-no-revoke --location --fail --retry 5 --retry-delay 5 --connect-timeout 20" +
                " --continue-at - --output " + q(path) +
                " --resolve " + q(f.host + ":" + f.port + ":" + ip) +
                " " + q(f.url);
            rc = shell.Run(cmd, 1, true);
            if (rc === 0 && fso.FileExists(path) && Number(fso.GetFile(path).Size) === f.size) {
                actual = hashSha1(path);
                if (actual === f.sha1) break;
            }
            if (attempt === 1) {
                try { if (fso.FileExists(path)) fso.DeleteFile(path, true); } catch (ex4) {}
                WScript.Echo("[RETRY] The file did not verify. Retrying once from the beginning.");
            }
        }

        if (rc !== 0 || !fso.FileExists(path) || Number(fso.GetFile(path).Size) !== f.size || hashSha1(path) !== f.sha1) {
            saveState("FAIL",
                "reason=Media file download or SHA-1 verification failed.\r\nfile=" + f.name + "\r\ncurl_rc=" + rc + "\r\n");
            WScript.Quit(rc === 0 ? 96 : 90);
        }

        completedBytes += f.size;
        WScript.Echo("[VERIFIED] " + f.name);
        WScript.Echo("Overall: " + gb(completedBytes) + " / " + gb(total) + " GiB");
    }

    saveState("PASS",
        "build=26100.8894\r\narch=amd64\r\nedition=core\r\nlanguage=en-us\r\n" +
        "file_count=" + files.length + "\r\ntotal_bytes=" + total + "\r\ndestination=" + dest + "\r\n");
    WScript.Echo("");
    WScript.Echo("============================================================");
    WScript.Echo("[PASS] WINDOWS RECOVERY SOURCE DOWNLOAD COMPLETE");
    WScript.Echo("All UUP source files passed SHA-1 verification.");
    WScript.Echo("RescueMeAI will report the result and remain online.");
    WScript.Echo("============================================================");
    WScript.Quit(0);
})();
