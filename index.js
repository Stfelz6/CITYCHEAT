// // $(function(){

// //     $(".dropdown-menu").on('click', 'li a', function(){
// //       $(".btn:first-child").text($(this).text());
// //       $(".btn:first-child").val($(this).text());
// //    });

// // });

window.onkeydown = function(evt) {
  if (evt.keyCode == "49") {
      alert("You chose the tram");
  }
  else if (evt.keyCode == "50") {
      alert("You chose the subway");
  }
  else if (evt.keyCode == "51") {
      alert("You chose the bus");
  }
  else if (evt.keyCode == "52") {
      alert("You chose the taxi");
  }
  else{
      alert("It's not a valid option");
  }
};