var uri = '';
var isPlaying;

function getEmbedCodeForURI(uri) {
    const track = uri.split(':')[2]
    const url = 'https://open.spotify.com/embed/track/' + track
    const code = '<iframe src="' + url + '" width="300" height="380" frameborder="0" allowtransparency="true" allow="encrypted-media"></iframe>'
    return code;
}

function setCurrentPlayingStatus() {
    const status = '<p id="space-ghost-icon">Listening right now</p>'
    $('#space-ghost-status').html(status)
    $(function () {
        setInterval(function () {
            $('#space-ghost-icon').fadeOut(800);
            $('#space-ghost-icon').fadeIn(800);
        }, 1600);
    });
}

function setLastPlayedStatus() {
    const status = '<p>Last Played</p>'
    $('#space-ghost-status').html(status)
}

function setStatus(isPlaying) {
    if (isPlaying) {
        return setCurrentPlayingStatus()
    }
    setLastPlayedStatus()
}



function setTrack(uri) {
    const embedCode = getEmbedCodeForURI(uri);
    $('#space-ghost').html(embedCode)
}

function pollTrack($) {
    $.get('https://space-ghost-odi6i.ondigitalocean.app/', function (data) {
        if (!data || !data.uri) {
            return
        }
        if (data.uri === uri) {
            if (isPlaying === data.isPlaying) {
                return
            }
            setStatus(data.isPlaying)
            return
        }
        uri = data.uri;

        setTrack(uri)
        setStatus(data.isPlaying)
    })
}

(function ($) {
    "use strict";

    $(document).ready(function(){
        pollTrack($)
        setInterval(
            function () {
                pollTrack($)
            },
            2*1000
        )
    });

}(jQuery));