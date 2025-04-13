<?php
namespace Home\Controller;

use Think\Controller;

class IndexController extends Controller
{
    public function Index()
    {
        $this->display("index");
    }

    /**
     * 登录功能
     */
    public function login()
    {
        $index = D("Index");
        $result = $index->loginCheck(I("post.username"), md5(I("post.password")),I("post.platform"));
        if($result["status"] == 1){
            session("plat",I("post.platform"));
        }
        $this->ajaxReturn($result);
    }

    /**
     * 系统首页初始
     */
    public function main()
    {
        checkSession();
        $params = array('serverid' => 0);
        $result = phpPostData("listserver",$params);
        foreach ($result["list"] as $key => $row) {
            $id[$key] = $row["id"];
            $ip[$key] = $row["ip"];
            $subid[$key] = $row["subid"];
            $param["serverid"] = intval($row["id"]);
            $param["subid"] = intval($row["subid"]);
            $serverInfo = phpPostData("getserverinfo",$param);
            $result["list"][$key]["day"] = $serverInfo["info"]["openday"];
            $result["list"][$key]["time"] = $serverInfo["info"]["opentime"];
            $result["list"][$key]["playernum"] = $serverInfo["info"]["playernum"];  
        }
        array_multisort($id, SORT_ASC, $ip, SORT_DESC, $result["list"]);
        session("serverList", $result["list"]);
        $this->display();
    }

    /**
     * 退出登录
     */
    public function logout()
    {
        session("[destroy]");
        $this->display("Index");
    }

    /**
     * 切换服务器
     * @param $serverId 服务器ID
     */
    public function changeServer($serverId)
    {
        if (intval($serverId) != 0) {
            session("serverid", $serverId);
            $this->ajaxReturn(1);
        } else {
            $this->ajaxReturn(0);
        }

    }

    public function verify()
    {
        $Verify = new \Think\Verify();
        $Verify->useImgBg = true;
        $Verify->entry();
    }
}
