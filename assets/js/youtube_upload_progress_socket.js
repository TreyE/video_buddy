import { Socket } from './phoenix';

$(document).ready(function() {
  var socket = new Socket("/socket");
  socket.connect();
  var x = socket;
  var yua_pbs = $('.yua_progress_bar');
  yua_pbs.each(function(_index, ele) {
    var element = $(ele);
    var status_text = $(".yua_progress_label[data-attempt-id='" + attempt_id + "']");
    var attempt_id = element.attr('data-attempt-id');
    var t_name = "youtube_upload_attempt:" + attempt_id;
    var channel = socket.channel(t_name);
    channel.join();
    channel.on("upload_progress_update",
      function(msg) {
         var progress = ((msg.uploaded * 1.0)/ msg.total) * 100.0;
         element.attr("aria-valuenow", Math.trunc(progress));
         element.css("width", progress.toString() + "%");
         status_text.text(msg.status);
      }
    )
  });
});