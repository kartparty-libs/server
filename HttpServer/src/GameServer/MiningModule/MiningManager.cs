using Google.Protobuf;
using Proto;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Data;

/// <summary>
/// 挖矿管理器
/// </summary>
public class MiningManager : BaseManager<MiningManager>
{
    /// <summary>
    /// 赛车挖矿池剩余token积分
    /// </summary>
    private long m_nCarTokenScorePoolValue = 0;

    /// <summary>
    /// 钻石挖矿池剩余token积分
    /// </summary>
    private long m_nDiamondTokenScorePoolValue = 0;

    /// <summary>
    /// 总挖矿玩家
    /// </summary>
    private ConcurrentDictionary<long, bool> m_pTotalMiningRoleIds = new ConcurrentDictionary<long, bool>();

    /// <summary>
    /// 总领取玩家
    /// </summary>
    private ConcurrentDictionary<long, bool> m_pTotalReceiveRoleIds = new ConcurrentDictionary<long, bool>();

    /// <summary>
    /// 赛车总挖矿价值
    /// </summary>
    private ConcurrentDictionary<long, long> m_pCarTotalMiningValues = new ConcurrentDictionary<long, long>();

    /// <summary>
    /// 钻石总挖矿价值
    /// </summary>
    private ConcurrentDictionary<long, long> m_pDiamondTotalMiningValues = new ConcurrentDictionary<long, long>();

    /// <summary>
    /// 全服赛车总挖矿人数
    /// </summary>
    private int m_nAllServerCarTotalMiningCount = 0;

    /// <summary> 
    /// 全服钻石总挖矿人数
    /// </summary>
    private int m_nAllServerDiamondTotalMiningCount = 0;

    /// <summary>
    /// 全服赛车总挖矿价值
    /// </summary>
    private long m_nAllServerCarTotalMiningValue = 0;

    /// <summary>
    /// 全服钻石总挖矿价值
    /// </summary>
    private long m_nAllServerDiamondTotalMiningValue = 0;

    public override void Initializer(DataRow i_pGlobalInfo, bool i_bIsFirstOpenServer)
    {
        base.Initializer(i_pGlobalInfo, i_bIsFirstOpenServer);
        DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eGameServer, SqlTableName.role_mininginfo);
        if (data != null && data.Rows.Count > 0)
        {
            for (int i = 0; i < data.Rows.Count; i++)
            {
                DataRow dataRow = data.Rows[i];
                long roleId = Convert.ToInt64(dataRow["roleid"]);

                string carminingdata = Convert.ToString(dataRow["carminingdata"]);
                var carMiningData = UtilityMethod.JsonDeserializeObject<MiningData>(carminingdata);
                if (carMiningData != null && carMiningData.value != 0)
                {
                    CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(carMiningData.value);
                    if (carUpgrade_Data != null)
                    {
                        m_pCarTotalMiningValues.TryAdd(roleId, 0);//carUpgrade_Data.MiningValue
                        m_pTotalMiningRoleIds.TryAdd(roleId, true);
                    }
                }

                string diamondminingdata = Convert.ToString(dataRow["diamondminingdata"]);
                var diamondMiningData = UtilityMethod.JsonDeserializeObject<MiningData>(diamondminingdata);
                if (diamondMiningData != null && diamondMiningData.value != 0)
                {
                    m_pDiamondTotalMiningValues.TryAdd(roleId, diamondMiningData.value);
                    m_pTotalMiningRoleIds.TryAdd(roleId, true);
                }

                long carsettlementtokenscore = Convert.ToInt64(dataRow["carsettlementtokenscore"]);
                long diamondsettlementtokenscore = Convert.ToInt64(dataRow["diamondsettlementtokenscore"]);
                if (carsettlementtokenscore > 0 || diamondsettlementtokenscore > 0)
                {
                    m_pTotalReceiveRoleIds.TryAdd(roleId, true);
                }
            }
        }
    }

    public override void Start()
    {
        base.Start();
        ReqMsgBodyCommonMiningData();
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取赛车挖矿池剩余token积分
    /// </summary>
    /// <returns></returns>
    public long GetCarTokenScorePoolValue()
    {
        return m_nCarTokenScorePoolValue;
    }

    /// <summary>
    /// 获取钻石挖矿池剩余token积分
    /// </summary>
    /// <returns></returns>
    public long GetDiamondTokenScorePoolValue()
    {
        return m_nDiamondTokenScorePoolValue;
    }

    /// <summary>
    /// 获取全服赛车总挖矿人数
    /// </summary>
    /// <returns></returns>
    public int GetAllServerCarTotalMiningCount()
    {
        return m_nAllServerCarTotalMiningCount;
    }

    /// <summary>
    /// 获取全服钻石总挖矿人数
    /// </summary>
    /// <returns></returns>
    public int GetAllServerDiamondTotalMiningCount()
    {
        return m_nAllServerDiamondTotalMiningCount;
    }

    /// <summary>
    /// 获取全服赛车总挖矿价值
    /// </summary>
    /// <returns></returns>
    public long GetAllServerCarTotalMiningValue()
    {
        return m_nAllServerCarTotalMiningValue;
    }

    /// <summary>
    /// 获取全服钻石总挖矿价值
    /// </summary>
    /// <returns></returns>
    public long GetAllServerDiamondTotalMiningValue()
    {
        return m_nAllServerDiamondTotalMiningValue;
    }

    /// <summary>
    /// 领取赛车Token积分
    /// </summary>
    public void ReceiveCarTokenScore(long i_nRoleId, long i_nReceiveCarTokenScore, Action<ResMsgBodyReceiveCarTokenScorePoolValue> i_fCallback)
    {
        if (m_nCarTokenScorePoolValue == 0)
        {
            i_fCallback?.Invoke(null);
            return;
        }

        ReqMsgServerData reqMagStoSData = new ReqMsgServerData();

        ReqMsgBodyReceiveCarTokenScorePoolValue reqMsgBodyReceiveCarTokenScorePoolValue = new ReqMsgBodyReceiveCarTokenScorePoolValue();
        reqMsgBodyReceiveCarTokenScorePoolValue.Value = i_nReceiveCarTokenScore;
        reqMsgBodyReceiveCarTokenScorePoolValue.TotalReceiveCount = m_pTotalReceiveRoleIds.Count;
        reqMsgBodyReceiveCarTokenScorePoolValue.NewReceive = !m_pTotalReceiveRoleIds.ContainsKey(i_nRoleId);

        reqMagStoSData.AddMessageData(reqMsgBodyReceiveCarTokenScorePoolValue);

        HttpClientWrapper.PostAsync(ServerConfig.GetStoSURL(ServerTypeEnum.eMiningServer), reqMagStoSData.GetSendMessages(), (byte[] responseBody) =>
        {
            List<IMessage> messages = GlobalDefine.ProtoManager.FromBytes(responseBody);
            if (messages.Count > 2)
            {
                ResMsgBodyReceiveCarTokenScorePoolValue resMsgBodyReceiveCarTokenScorePoolValue = messages[1] as ResMsgBodyReceiveCarTokenScorePoolValue;
                ResMsgBodyCommonMiningData resMsgBodyCommonMiningData = messages[2] as ResMsgBodyCommonMiningData;
                UpdateCommonMiningData(resMsgBodyCommonMiningData);

                if (resMsgBodyReceiveCarTokenScorePoolValue.Value > 0)
                {
                    m_pTotalReceiveRoleIds.TryAdd(i_nRoleId, true);
                }

                i_fCallback?.Invoke(resMsgBodyReceiveCarTokenScorePoolValue);
            }
        });
    }

    /// <summary>
    /// 领取钻石Token积分
    /// </summary>
    public void ReceiveDiamondTokenScore(long i_nRoleId, long i_nReceiveDiamondTokenScore, Action<ResMsgBodyReceiveDiamondTokenScorePoolValue> i_fCallback)
    {
        if (m_nDiamondTokenScorePoolValue == 0)
        {
            i_fCallback?.Invoke(null);
            return;
        }

        ReqMsgServerData reqMagStoSData = new ReqMsgServerData();

        ReqMsgBodyReceiveDiamondTokenScorePoolValue reqMsgBodyReceiveDiamondTokenScorePoolValue = new ReqMsgBodyReceiveDiamondTokenScorePoolValue();
        reqMsgBodyReceiveDiamondTokenScorePoolValue.Value = i_nReceiveDiamondTokenScore;
        reqMsgBodyReceiveDiamondTokenScorePoolValue.TotalReceiveCount = m_pTotalReceiveRoleIds.Count;
        reqMsgBodyReceiveDiamondTokenScorePoolValue.NewReceive = !m_pTotalReceiveRoleIds.ContainsKey(i_nRoleId);

        reqMagStoSData.AddMessageData(reqMsgBodyReceiveDiamondTokenScorePoolValue);

        HttpClientWrapper.PostAsync(ServerConfig.GetStoSURL(ServerTypeEnum.eMiningServer), reqMagStoSData.GetSendMessages(), (byte[] responseBody) =>
        {
            List<IMessage> messages = GlobalDefine.ProtoManager.FromBytes(responseBody);
            if (messages.Count > 2)
            {
                ResMsgBodyReceiveDiamondTokenScorePoolValue resMsgBodyReceiveDiamondTokenScorePoolValue = messages[1] as ResMsgBodyReceiveDiamondTokenScorePoolValue;
                ResMsgBodyCommonMiningData resMsgBodyCommonMiningData = messages[2] as ResMsgBodyCommonMiningData;
                UpdateCommonMiningData(resMsgBodyCommonMiningData);

                if (resMsgBodyReceiveDiamondTokenScorePoolValue.Value > 0)
                {
                    m_pTotalReceiveRoleIds.TryAdd(i_nRoleId, true);
                }
                
                i_fCallback?.Invoke(resMsgBodyReceiveDiamondTokenScorePoolValue);
            }
        });
    }

    /// <summary>
    /// 玩家改变赛车挖矿价值
    /// </summary>
    /// <param name="i_nRoleId"></param>
    /// <param name="i_nCarValue"></param>
    public void PlayerChangeCarMiningValue(long i_nRoleId, long i_nCarValue)
    {
        if (i_nCarValue == 0)
        {
            m_pCarTotalMiningValues.TryRemove(i_nRoleId, out long value);
            if (!m_pDiamondTotalMiningValues.ContainsKey(i_nRoleId))
            {
                m_pTotalMiningRoleIds.TryRemove(i_nRoleId, out bool b);
            }
        }
        else
        {
            m_pCarTotalMiningValues.AddOrUpdate(i_nRoleId, i_nCarValue, (key, oldValue) => i_nCarValue);
            m_pTotalMiningRoleIds.TryAdd(i_nRoleId, true);
        }

        ReqMsgBodyCommonMiningData();
    }

    /// <summary>
    /// 玩家改变钻石挖矿价值
    /// </summary>
    /// <param name="i_nRoleId"></param>
    /// <param name="i_nDiamondValue"></param>
    public void PlayerChangeDiamondMiningValue(long i_nRoleId, long i_nDiamondValue)
    {
        if (i_nDiamondValue == 0)
        {
            m_pDiamondTotalMiningValues.TryRemove(i_nRoleId, out long value);
            if (!m_pCarTotalMiningValues.ContainsKey(i_nRoleId))
            {
                m_pTotalMiningRoleIds.TryRemove(i_nRoleId, out bool b);
            }
        }
        else
        {
            m_pDiamondTotalMiningValues.AddOrUpdate(i_nRoleId, i_nDiamondValue, (key, oldValue) => i_nDiamondValue);
            m_pTotalMiningRoleIds.TryAdd(i_nRoleId, true);
        }

        ReqMsgBodyCommonMiningData();
    }

    /// <summary>
    /// 更新公共挖矿服数据
    /// </summary>
    /// <returns></returns>
    public void UpdateCommonMiningData(ResMsgBodyCommonMiningData i_pResMsgBodyCommonMiningData)
    {
        if (i_pResMsgBodyCommonMiningData == null)
        {
            return;
        }
        m_nCarTokenScorePoolValue = i_pResMsgBodyCommonMiningData.CarTokenScorePoolValue;
        m_nDiamondTokenScorePoolValue = i_pResMsgBodyCommonMiningData.DiamondTokenScorePoolValue;
        m_nAllServerCarTotalMiningCount = i_pResMsgBodyCommonMiningData.AllServerCarTotalMiningCount;
        m_nAllServerCarTotalMiningValue = i_pResMsgBodyCommonMiningData.AllServerCarTotalMiningValue;
        m_nAllServerDiamondTotalMiningCount = i_pResMsgBodyCommonMiningData.AllServerDiamondTotalMiningCount;
        m_nAllServerDiamondTotalMiningValue = i_pResMsgBodyCommonMiningData.AllServerDiamondTotalMiningValue;
    }

    /// <summary>
    /// 请求公共挖矿服数据
    /// </summary>
    /// <returns></returns>
    public void ReqMsgBodyCommonMiningData()
    {
        ReqMsgServerData reqMagStoSData = new ReqMsgServerData();
        ReqMsgBodyCommonMiningData reqMsgBodyCommonMiningData = new ReqMsgBodyCommonMiningData();
        reqMsgBodyCommonMiningData.TotalMiningCount = m_pTotalMiningRoleIds.Count;
        reqMsgBodyCommonMiningData.TotalReceiveCount = m_pTotalReceiveRoleIds.Count;

        Dictionary<long, long> carTotalMiningValues = m_pCarTotalMiningValues.ToDictionary();
        reqMsgBodyCommonMiningData.CarTotalMiningCount = carTotalMiningValues.Count;
        foreach (var item in carTotalMiningValues)
        {
            reqMsgBodyCommonMiningData.CarTotalMiningValue += item.Value;
        }

        Dictionary<long, long> diamondTotalMiningValues = m_pDiamondTotalMiningValues.ToDictionary();
        reqMsgBodyCommonMiningData.DiamondTotalMiningCount = diamondTotalMiningValues.Count;
        foreach (var item in diamondTotalMiningValues)
        {
            reqMsgBodyCommonMiningData.DiamondTotalMiningValue += item.Value;
        }

        reqMagStoSData.AddMessageData(reqMsgBodyCommonMiningData);

        HttpClientWrapper.PostAsync(ServerConfig.GetStoSURL(ServerTypeEnum.eMiningServer), reqMagStoSData.GetSendMessages(), (byte[] responseBody) =>
        {
            List<IMessage> messages = GlobalDefine.ProtoManager.FromBytes(responseBody);
            if (messages.Count > 1)
            {
                ResMsgBodyCommonMiningData resMsgBodyCommonMiningData = messages[1] as ResMsgBodyCommonMiningData;
                UpdateCommonMiningData(resMsgBodyCommonMiningData);
            }
        });
    }
}
