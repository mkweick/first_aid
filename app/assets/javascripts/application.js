//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require jquery.turbolinks
//= require bootstrap
//= require_tree .

$(document).ready(function() {
  $('#new_card_btn').click(function() {
    var date = new Date();
    var year_today = date.getFullYear().toString().slice(2);
    var month_today = (date.getMonth() + 1).toString();
    if (month_today.length == 1) {
      var month_today = '0' + month_today;
    }
    
    if ($('#new_card').is(':visible')) {
      var response = confirm('Are you sure you want to cancel Credit Card?');
      if (response == true) {
        $('#errors').hide();
        $('#new_card').hide();
        $('#new_card_btn').text('New Card');
        $('#new_card_btn').removeClass('btn-danger').addClass('btn-primary');
        $('#cc_num').val('');
        $('#cc_name').val('');
        $('#cc_exp_mth').val(month_today);
        $('#cc_exp_year').val(year_today);
        $('#cc_line1').val('');
        $('#cc_city').val('');
        $('#cc_state').val('NY');
        $('#cc_zip').val('');
        $('#cards_on_file').show();
      }
    } else {
      $('#new_card').show();
      $('#cc_exp_mth').val(month_today);
      $('#cc_exp_year').val(year_today);
      $('#cc_state').val('NY');
      $('#new_card_btn').text('Cancel New Card');
      $('#new_card_btn').removeClass('btn-primary').addClass('btn-danger');
      $('#cards_on_file').hide();
    }
  });

  if($('#errors').length > 0) {
    document.querySelector('#errors').scrollIntoView();
  }
});
