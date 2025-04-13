/**
 * Created by huhaoran on 2016/3/21.
 */
function loadUrl(url) {
    $(".content").load(url);
}
function bottomPage(url, page, pageCount) {
    page = parseInt(page);
    $("#pageContent").html("共" + pageCount + "页&nbsp;&nbsp;当前第<input type='text' style='width: 50px;' value='"+page+"' id='page'>页&nbsp;&nbsp; "+
        "<a onclick=turnPage('" + url + "',1)>首页</a>&nbsp;&nbsp;"+
        "<a onclick=turnPage('" + url + "'," + (page - 1) + ")>上一页</a>&nbsp;&nbsp;"+
        "<a onclick=turnPage('" + url + "'," + (page + 1) + ")>下一页</a>&nbsp;&nbsp;"+
        "<a onclick=turnPage('" + url + "'," + pageCount + ")>尾页</a>");
    $("#page").bind("change",function(){
        turnPage(url,$(this).val());
    });
}
function turnPage(url, pageNum) {
    $(".content").load(url + "/page/" + pageNum);
}

