// WR-MODULE: uup-select-build-js 2026.08.15-1040-ET
(function () {
    var a = WScript.Arguments;
    if (a.length < 3) WScript.Quit(64);
    var jsonPath = String(a(0));
    var wantBuild = String(a(1));
    var wantArch = String(a(2)).toLowerCase();
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    if (!fso.FileExists(jsonPath)) WScript.Quit(90);
    var f = fso.OpenTextFile(jsonPath, 1, false), raw = f.ReadAll();
    f.Close();
    var root = null;
    try { root = eval("(" + raw + ")"); } catch (e) { WScript.Quit(96); }
    if (!root || !root.response || !root.response.builds) WScript.Quit(96);
    var builds = root.response.builds, best = null, i, b, title, created;
    for (i = 0; i < builds.length; i++) {
        b = builds[i];
        if (String(b.build || "") !== wantBuild) continue;
        if (String(b.arch || "").toLowerCase() !== wantArch) continue;
        title = String(b.title || "");
        if (title.toLowerCase().indexOf("windows 11") < 0) continue;
        if (title.toLowerCase().indexOf("server") >= 0) continue;
        created = Number(b.created || 0);
        if (!best || created > Number(best.created || 0)) best = b;
    }
    if (!best || !best.uuid) WScript.Quit(10);
    WScript.Echo("BUILD=" + String(best.build));
    WScript.Echo("ARCH=" + String(best.arch).toLowerCase());
    WScript.Echo("UUID=" + String(best.uuid));
    WScript.Echo("CREATED=" + String(best.created || ""));
    WScript.Echo("TITLE=" + String(best.title || "").replace(/[\r\n=]/g, " "));
    WScript.Quit(0);
})();