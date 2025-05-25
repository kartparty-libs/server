using Google.Protobuf;
using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 排行榜管理器
/// </summary>
public class RankManager : BaseManager<RankManager>
{
    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);
    }

    public override void Start()
    {
        base.Start();
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 更新排行数据
    /// </summary>
    /// <param name="i_pReqMsgBodyUpdateRankData"></param>
    private void UpdateRankData(ReqMsgBodyUpdateRankData i_pReqMsgBodyUpdateRankData)
    {
        ReqMsgServerData reqMagStoSData = new ReqMsgServerData();
        reqMagStoSData.AddMessageData(i_pReqMsgBodyUpdateRankData);
        //Debug.Instance.Log($"RankManager UpdateRankData key = {i_pReqMsgBodyUpdateRankData.Key}  value = {i_pReqMsgBodyUpdateRankData.Value}");
        HttpClientWrapper.PostAsync(ServerConfig.GetStoSURL(ServerTypeEnum.eRankServer), reqMagStoSData.GetSendMessages());
    }

    /// <summary>
    /// 排行值变化通知_玩家简要信息
    /// </summary>
    /// <param name="i_eRankTypeEnum"></param>
    /// <param name="i_nKey"></param>
    /// <param name="i_nValue"></param>
    /// <param name="i_pPlayer"></param>
    public void OnChangeRankValue(RankTypeEnum i_eRankTypeEnum, long i_nKey, long i_nValue, Player i_pPlayer)
    {
        ReqMsgBodyUpdateRankData reqMsgBodyUpdateRankData = new ReqMsgBodyUpdateRankData();
        reqMsgBodyUpdateRankData.RankTypeEnum = i_eRankTypeEnum;
        reqMsgBodyUpdateRankData.Key = i_nKey;
        reqMsgBodyUpdateRankData.Values.Add(i_nValue);

        RankOtherInfo_PlayerInfo rankOtherInfo_PlayerInfo = new RankOtherInfo_PlayerInfo();
        rankOtherInfo_PlayerInfo.serverId = ServerConfig.ServerId;
        rankOtherInfo_PlayerInfo.roleId = i_pPlayer.GetRoleId();
        rankOtherInfo_PlayerInfo.name = i_pPlayer.GetName();
        rankOtherInfo_PlayerInfo.headId = i_pPlayer.GetSystem<BaseInfoSystem>().GetHeadId();
        rankOtherInfo_PlayerInfo.email = i_pPlayer.GetEMail();
        reqMsgBodyUpdateRankData.OtherInfo = UtilityMethod.JsonSerializeObject(rankOtherInfo_PlayerInfo);
        this.UpdateRankData(reqMsgBodyUpdateRankData);
    }

    /// <summary>
    /// 排行值变化通知_玩家简要信息
    /// </summary>
    /// <param name="i_eRankTypeEnum"></param>
    /// <param name="i_nKey"></param>
    /// <param name="i_tValue"></param>
    /// <param name="i_pPlayer"></param>
    public void OnChangeRankValue(RankTypeEnum i_eRankTypeEnum, long i_nKey, List<long> i_tValue, Player i_pPlayer)
    {
        ReqMsgBodyUpdateRankData reqMsgBodyUpdateRankData = new ReqMsgBodyUpdateRankData();
        reqMsgBodyUpdateRankData.RankTypeEnum = i_eRankTypeEnum;
        reqMsgBodyUpdateRankData.Key = i_nKey;
        for (int i = 0; i < i_tValue.Count; i++)
        {
            reqMsgBodyUpdateRankData.Values.Add(i_tValue[i]);
        }

        RankOtherInfo_PlayerInfo rankOtherInfo_PlayerInfo = new RankOtherInfo_PlayerInfo();
        rankOtherInfo_PlayerInfo.serverId = ServerConfig.ServerId;
        rankOtherInfo_PlayerInfo.roleId = i_pPlayer.GetRoleId();
        rankOtherInfo_PlayerInfo.name = i_pPlayer.GetName();
        rankOtherInfo_PlayerInfo.headId = i_pPlayer.GetSystem<BaseInfoSystem>().GetHeadId();
        rankOtherInfo_PlayerInfo.email = i_pPlayer.GetEMail();
        reqMsgBodyUpdateRankData.OtherInfo = UtilityMethod.JsonSerializeObject(rankOtherInfo_PlayerInfo);
        this.UpdateRankData(reqMsgBodyUpdateRankData);
    }
}

/// <summary>
/// 排行榜其他信息_玩家简要信息
/// </summary>
public class RankOtherInfo_PlayerInfo
{
    public int serverId;
    public long roleId;
    public string name = "";
    public int headId = 1;
    public string email = "";
}