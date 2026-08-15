// RescueMeAI local JSON helper for WinRE/cscript.
// Usage: cscript //nologo json-value-v1.js <json-file> <property>
// Intentionally avoids JSON.parse for compatibility with older WinRE JScript engines.
(function () {
    if (WScript.Arguments.length < 2) WScript.Quit(64);
    var path = WScript.Arguments.Item(0);
    var key = WScript.Arguments.Item(1);

    function escapeRe(s) {
        return s.replace(/([\\.^$*+?()\[\]{}|])/g, "\\$1");
    }

    function unescapeJsonString(s) {
        return s
            .replace(/\\\"/g, '"')
            .replace(/\\\\/g, "\\")
            .replace(/\\\//g, "/")
            .replace(/\\b/g, "\b")
            .replace(/\\f/g, "\f")
            .replace(/\\n/g, "\n")
            .replace(/\\r/g, "\r")
            .replace(/\\t/g, "\t")
            .replace(/\\u([0-9a-fA-F]{4})/g, function (_, h) {
                return String.fromCharCode(parseInt(h, 16));
            });
    }

    try {
        var fso = new ActiveXObject("Scripting.FileSystemObject");
        if (!fso.FileExists(path)) WScript.Quit(2);
        var ts = fso.OpenTextFile(path, 1, false, -2);
        var text = ts.ReadAll();
        ts.Close();

        // GitHub's OAuth/device-flow replies are flat JSON objects. Extract only
        // a requested top-level scalar field; no eval/JSON.parse dependency.
        var re = new RegExp('"' + escapeRe(key) + '"\\s*:\\s*(?:"((?:\\\\.|[^"\\\\])*)"|(-?[0-9]+(?:\\.[0-9]+)?)|(true|false|null))', 'i');
        var m = re.exec(text);
        if (!m) WScript.Quit(3);

        var value;
        if (typeof m[1] !== "undefined" && m[1] !== undefined) {
            value = unescapeJsonString(m[1]);
        } else if (typeof m[2] !== "undefined" && m[2] !== undefined) {
            value = m[2];
        } else {
            value = m[3];
            if (String(value).toLowerCase() === "null") WScript.Quit(3);
        }
        WScript.Echo(String(value));
        WScript.Quit(0);
    } catch (e) {
        WScript.Quit(4);
    }
})();
