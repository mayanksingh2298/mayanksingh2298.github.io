var uri = '';
var isPlaying;

function getEmbedCodeForURI(uri) {
    const track = uri.split(':')[2]
    const url = 'https://open.spotify.com/embed/track/' + track
    const code = '<iframe src="' + url + '" width="300" height="380" frameborder="0" allowtransparency="true" allow="encrypted-media"></iframe>'
    return code;
}



function setTrack($) {
    $.get('https://space-ghost.vercel.app/api/', function (data) {
        if (!data || !data.uri) {
            return
        }
        if (data.uri === uri) {
            if (isPlaying === data.isPlaying) {
                return
            }
            const status = data.isPlaying ? 'Currently Playing' : 'Last Played'
            $('#space-ghost-status').text(status)
            return
        }
        uri = data.uri;

        const embedCode = getEmbedCodeForURI(data.uri);
        $('#space-ghost').html(embedCode)
        const status = data.isPlaying ? 'Currently Playing' : 'Last Played'
        $('#space-ghost-status').text(status)
    })
}

(function ($) {
    "use strict";

    $(document).ready(function(){
        setTrack($)
        setInterval(
            function () {
                setTrack($)
            },
            5*1000
        )
    });

}(jQuery));