<?php
namespace Home\Controller;

use Think\Controller;

class UserInfoController extends Controller
{
    /**
     * 后台用户列表
     */
    public function show()
    {
        checkSession();
        $userInfo = D("UserInfo");
        $result = $userInfo->select();
        $this->assign("userInfo", $result);
        $this->display("userinfo");
    }

    public function addUserPage()
    {
        checkSession();
        $this->display("addPage");
    }

    /**
     * 删除后台用户
     * @param $id 后台用户ID
     */
    public function deluser($id)
    {
        checkSession();
        try {
            $userInfo = D("UserInfo");
            $userInfo->delete($id);
            $result["status"] = 1;
        } catch (Exception $e) {
            $result["status"] = 0;
        }
        $this->ajaxReturn(json_encode($result));
    }

    /**
     * 查询管理后台用户操作日志
     * @param $page 当前页数
     */
    public function operateLog()
    {
        checkSession();
        $this->assign("result", createPageResult("OperateLog",I("get.page"),null));
        $this->display("operateLog");
    }
}
