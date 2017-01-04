// new tab from 'a' link
$('.post-content>a').attr('target','_blank');

// make bookmark
$('.post-content>h2').wrap('<a href="#index-table" style="text-decoration:none" ></a>');

// append index
$('.post-content>a>h2').each(function(){
    var text = $(this).text();
    var link = text.replace(/[\.,'’]|[0-9]/g, '');
    link = link.trim(link);
    link = link.replace(/ /g, '-');
    link = link.toLowerCase();
    return $("<a href='#" + link + "'>" + text + "</a><br>").appendTo('#index-table');
});

// liquid parsing
//$('#keyword').attr('class', window.location.href);
