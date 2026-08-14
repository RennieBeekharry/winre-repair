// WinRE-safe UUP dump JSON downloader/verifier.
// Uses only Windows Script Host plus the caller-supplied curl/certutil/nslookup binaries.
// No disk, partition, format, registry, boot, or Windows-image write operations exist here.

(function () {
    var a = WScript.Arguments;
    if (a.length < 8) WScript.Quit(20);

    var jsonPath = a(0);
    var destDir = a(1);
    var expectedBuild = a(2);
    var curl = a(3);
    var certutil = a(4);
    var nslookup = a(5);
    var dns = a(6);
    var statePath = a(7);

    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var shell = new ActiveXObject("WScript.Shell");

    function quote(s) {
        return '"' + String(s).replace(/"/g, '\\"') + '"';
    }

    function readAll(path) {
        var t = fso.OpenTextFile(path, 1, false);
        var s = t.ReadAll();
        t.Close();
        return s;
    }

    function writeState(status, done, total, current, message) {
        try {
            var t = fso.CreateTextFile(statePath, true, false);
            t.WriteLine("status=" + status);
            t.WriteLine("done=" + done);
            t.WriteLine("total=" + total);
            t.WriteLine("current=" + current);
            t.WriteLine("message=" + message);
            t.Close();
        } catch (e) {}
    }

    function exec(cmd) {
        var p = shell.Exec(cmd);
        while (p.Status === 0) WScript.Sleep(100);
        var out = "";
        try { out += p.StdOut.ReadAll(); } catch (e1) {}
        try { out += p.StdErr.ReadAll(); } catch (e2) {}
        return { code: p.ExitCode, out: out };
    }

    function sha1(path) {
        var r = exec(quote(certutil) + " -hashfile " + quote(path) + " SHA1");
        if (r.code !== 0) return "";
        var m = r.out.match(/\b[0-9a-fA-F]{40}\b/);
        return m ? m[0].toLowerCase() : "";
    }

    function resolveHost(host) {
        var r = exec(quote(nslookup) + " " + host + " " + dns);
        if (r.code !== 0) return "";
        var matches = r.out.match(/\b(?:\d{1,3}\.){3}\d{1,3}\b/g);
        if (!matches) return "";
        for (var i = matches.length - 1; i >= 0; i--) {
            if (matches[i] !== dns) return matches[i];
        }
        return "";
    }

    function hostFromUrl(url) {
        var m = /^https?:\/\/([^\/:]+)/i.exec(url);
        return m ? m[1] : "";
    }

    function download(url, partPath) {
        var host = hostFromUrl(url);
        var https = /^https:/i.test(url);
        var ip = host ? resolveHost(host) : "";
        var port = https ? "443" : "80";
        var base = quote(curl) + " --ssl-no-revoke --fail --location --silent --show-error --retry 4 --retry-delay 3 --connect-timeout 20 --max-time 7200 ";
        if (ip) base += "--resolve " + quote(host + ":" + port + ":" + ip) + " ";

        var resume = fso.FileExists(partPath);
        var cmd = base + (resume ? "--continue-at - " : "") + quote(url) + " -o " + quote(partPath);
        var r = exec(cmd);
        if (r.code === 0) return true;

        // A stale/partial range can occasionally be rejected by a newly issued Microsoft URL.
        // Retry once from zero after deleting only this downloader's .part file.
        if (resume) {
            try { fso.DeleteFile(partPath, true); } catch (e) {}
            r = exec(base + quote(url) + " -o " + quote(partPath));
            if (r.code === 0) return true;
        }
        return false;
    }

    if (!fso.FileExists(jsonPath)) {
        writeState("ERROR", 0, 0, "", "JSON response missing");
        WScript.Quit(21);
    }
    if (!fso.FolderExists(destDir)) fso.CreateFolder(destDir);

    var data;
    try {
        data = eval("(" + readAll(jsonPath) + ")");
    } catch (e) {
        writeState("ERROR", 0, 0, "", "JSON parse failed");
        WScript.Quit(22);
    }

    if (!data || !data.response || data.response.error) {
        var em = data && data.response && data.response.error ? String(data.response.error) : "Missing response object";
        writeState("ERROR", 0, 0, "", em);
        WScript.Quit(23);
    }

    var response = data.response;
    if (String(response.build) !== String(expectedBuild)) {
        writeState("ERROR", 0, 0, "", "Unexpected build " + response.build);
        WScript.Quit(24);
    }
    if (String(response.arch).toLowerCase() !== "amd64") {
        writeState("ERROR", 0, 0, "", "Unexpected architecture " + response.arch);
        WScript.Quit(25);
    }
    if (!response.files) {
        writeState("ERROR", 0, 0, "", "API returned no files");
        WScript.Quit(26);
    }

    var list = [];
    var totalBytes = 0;
    for (var name in response.files) {
        if (!response.files.hasOwnProperty(name)) continue;
        var x = response.files[name];
        if (!x || !x.url || !x.sha1 || !x.size) continue;
        list.push({ name: name, url: String(x.url), sha1: String(x.sha1).toLowerCase(), size: parseInt(x.size, 10) || 0 });
        totalBytes += parseInt(x.size, 10) || 0;
    }
    if (list.length === 0) {
        writeState("ERROR", 0, 0, "", "No downloadable files in API response");
        WScript.Quit(27);
    }

    try {
        var driveName = destDir.substr(0, 2);
        var drive = fso.GetDrive(driveName);
        var reserve = 1073741824; // 1 GiB safety margin.
        if (drive.FreeSpace < totalBytes + reserve) {
            writeState("ERROR", 0, list.length, "", "Insufficient free space");
            WScript.Quit(28);
        }
    } catch (eSpace) {
        writeState("ERROR", 0, list.length, "", "Could not verify free space");
        WScript.Quit(29);
    }

    var done = 0;
    writeState("DOWNLOADING", done, list.length, "", "Validated UUP JSON API response");

    for (var i = 0; i < list.length; i++) {
        var item = list[i];
        var safeName = item.name.replace(/[\\\/:*?"<>|]/g, "_");
        var finalPath = destDir + "\\" + safeName;
        var partPath = finalPath + ".part";
        var shown = "[" + (i + 1) + "/" + list.length + "] " + safeName;
        WScript.Echo(shown);
        writeState("DOWNLOADING", done, list.length, safeName, "Downloading/verifying");

        if (fso.FileExists(finalPath)) {
            if (sha1(finalPath) === item.sha1) {
                done++;
                continue;
            }
            try { fso.DeleteFile(finalPath, true); } catch (eDel) {
                writeState("ERROR", done, list.length, safeName, "Existing file hash mismatch and could not be replaced");
                WScript.Quit(30);
            }
        }

        if (!download(item.url, partPath)) {
            writeState("PAUSED", done, list.length, safeName, "Download failed; rerun is safe");
            WScript.Quit(31);
        }

        if (sha1(partPath) !== item.sha1) {
            try { fso.DeleteFile(partPath, true); } catch (eBad) {}
            writeState("PAUSED", done, list.length, safeName, "SHA-1 verification failed; rerun is safe");
            WScript.Quit(32);
        }

        try {
            if (fso.FileExists(finalPath)) fso.DeleteFile(finalPath, true);
            fso.MoveFile(partPath, finalPath);
        } catch (eMove) {
            writeState("PAUSED", done, list.length, safeName, "Verified file could not be finalized");
            WScript.Quit(33);
        }
        done++;
    }

    writeState("COMPLETE", done, list.length, "", "All UUP files SHA-1 verified");
    WScript.Quit(0);
})();
