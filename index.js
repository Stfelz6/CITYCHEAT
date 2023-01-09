window.onkeydown = function(evt) {
   var trainNo = document.getElementById('trainNo');
   var subwayNo = document.getElementById('subwayNo');
   var busNo = document.getElementById('busNo');
   var taxiNo = document.getElementById('taxiNo');

 if (evt.keyCode == "49") {
     //alert("You chose the tram");
     trainNo.style.display='block';
     subwayNo.style.display='none';
     busNo.style.display='none';
     taxiNo.style.display='none';
 }
 else if (evt.keyCode == "50") {
     //alert("You chose the subway");
     trainNo.style.display='none';
     subwayNo.style.display='block';
     busNo.style.display='none';
     taxiNo.style.display='none';
 }
 else if (evt.keyCode == "51") {
     //alert("You chose the bus");
     trainNo.style.display='none';
     subwayNo.style.display='none';
     busNo.style.display='block';
     taxiNo.style.display='none';
 }
 else if (evt.keyCode == "52") {
     //alert("You chose the taxi");
     trainNo.style.display='none';
     subwayNo.style.display='none';
     busNo.style.display='none';
     taxiNo.style.display='block';
 }
};

let myVar = setInterval(myTimer, 2500);
function myTimer() {
 document.getElementById("logomare").style.display = 'none';
}