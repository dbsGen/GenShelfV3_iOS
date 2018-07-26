var getPages = function() {
    if (this['arr_pages']) {
        return arr_pages;
    }else {
        var data = JSON.parse(pages.replace(/\r\n/g, '|'));
        return data.page_url.split('|');
    }
};