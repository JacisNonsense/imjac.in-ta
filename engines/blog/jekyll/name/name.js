var fadein = function() {
    namecontainer.style.opacity = "1";
    setTimeout(function() {
        nameprocontainer.style.opacity = "1";
        setTimeout(function() {
            nameipcontainer.style.opacity = "1";
        }, 100);
    }, 100);
};

var manipulate = function(step) {
    for (var i = 0; i < 9; i++) {
        if (step < i) {
            document.getElementById("namecomponent_" + i).style.opacity = 0;
            document.getElementById("namepcomponent_" + i).style.opacity = 0;
            document.getElementById("nameipcomponent_" + i).style.opacity = 0;
        } else {
            document.getElementById("namecomponent_" + i).style.opacity = 1;
            document.getElementById("namepcomponent_" + i).style.opacity = 1;
            document.getElementById("nameipcomponent_" + i).style.opacity = 1;
        }
    };
};

var final = function() {
    document.getElementById("namecomponent_3").style.opacity = 0;
    document.getElementById("nameipcomponent_3").style.opacity = 0;
    setTimeout(function() {
        document.getElementById("namecomponent_3").innerHTML = "";
        document.getElementById("nameipcomponent_3").innerHTML = "";
        document.getElementById("namepcomponent_4").style.opacity = "0";
        document.getElementById("nameipcomponent_4").style.opacity = "0";
        wait(function() {
            document.getElementById("namepcomponent_4").innerHTML = "s e a";
            document.getElementById("nameipcomponent_4").innerHTML = "s i:";
            document.getElementById("namepcomponent_4").style.opacity = "1";
            document.getElementById("nameipcomponent_4").style.opacity = "1";
        });
    }, 250);
};

var wait = function(func) {
    setTimeout(func, 350);
};

window.onload = function() {
    setTimeout(function() {
        manipulate(9);
        setTimeout(function() {
            manipulate(8);
            wait(function() {
                manipulate(7);
                wait(function() {
                    manipulate(6);
                    wait(function() {
                        manipulate(5);
                        wait(function() {
                            manipulate(4);
                            final();
                        });
                    });
                });
            });
        }, 1500);
        fadein();
    }, 100);
};