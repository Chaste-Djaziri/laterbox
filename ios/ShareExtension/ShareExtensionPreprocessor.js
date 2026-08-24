var ShareExtensionPreprocessor = function() {};

ShareExtensionPreprocessor.prototype = {
    run: function(arguments) {
        var selection = "";
        try {
            if (window.getSelection) {
                selection = window.getSelection().toString().trim();
            }
        } catch (e) {}

        arguments.completionFunction({
            "url": window.location.href,
            "title": document.title || "",
            "selection": selection
        });
    },
    finalize: function(arguments) {
        // Nothing needed here
    }
};

var ExtensionPreprocessingJS = new ShareExtensionPreprocessor();
