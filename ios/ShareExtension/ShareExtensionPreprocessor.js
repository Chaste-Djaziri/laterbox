var ShareExtensionPreprocessor = function() {};

ShareExtensionPreprocessor.prototype = {
    run: function(args) {
        var selection = "";
        try {
            if (window.getSelection) {
                selection = window.getSelection().toString().trim();
            }
        } catch (e) {}

        args.completionFunction({
            "url": window.location.href,
            "title": document.title || "",
            "selection": selection
        });
    },
    finalize: function(args) {
        // Nothing needed here
    }
};

var ExtensionPreprocessingJS = new ShareExtensionPreprocessor();
