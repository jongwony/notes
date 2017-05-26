// new tab from 'a' link
$('.post-content a').each(function(){
    var text = $(this).attr('href');
    var first = text.charAt(0);
    if(first != '#'){
        $(this).attr('target', '_blank');
    }
});

// make bookmark
$('.post-content>h2').wrap('<a href="#index-table" style="text-decoration:none" ></a>');

// append index
$('.post-content>a>h2').each(function(){
    var text = $(this).text();
    var link = text.replace(/[\*\.,'’/]/g, '');
    link = link.trim(link);
    link = link.replace(/ /g, '-');
    link = link.toLowerCase();
    return $("<a href='#" + link + "'>" + text + "</a><br>").appendTo('#index-table');
});

// liquid parsing
//$('#keyword').attr('class', window.location.href);

// Fork me on a GitHub!
$('.gitribbon').append('<img style="position: fixed; top: 50px; right: 0; border: 0;" src="//camo.githubusercontent.com/652c5b9acfaddf3a9c326fa6bde407b87f7be0f4/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f6f72616e67655f6666373630302e706e67" alt="GitHub Link" data-canonical-src="//s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png">')