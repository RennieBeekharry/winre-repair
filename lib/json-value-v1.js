// RescueMeAI local JSON helper for WinRE/cscript.
// Usage: cscript //nologo json-value-v1.js <json-file> <property>
(function () {
    if (WScript.Arguments.length < 2) WScript.Quit(64);
    var path = WScript.Arguments.Item(0);
    var key = WScript.Arguments.Item(1);
    try {
        var fso = new ActiveXObject("Scripting.FileSystemObject");
        if (!fso.FileExists(path)) WScript.Quit(2);
        var ts = fso.OpenTextFile(path, 1, false, -2);
        var text = ts.ReadAll();
        ts.Close();
        var obj = JSON.parse(text);
        if (!obj || typeof obj[key] === "undefined" || obj[key] === null) WScript.Quit(3);
        WScript.Echo(String(obj[key]));
        WScript.Quit(0);
    } catch (e) {
        WScript.Quit(4);
    }
})();
