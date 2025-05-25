using Google.Protobuf;
using Newtonsoft.Json.Linq;
using Proto;
using System.Data;

/// <summary>
/// 宝箱系统
/// </summary>
public class TreasureSystem : BasePlayerSystem
{
    /// <summary>
    /// 宝箱id自增
    /// </summary>
    private int m_nTreasureChestIndex = 0;

    /// <summary>
    /// 宝箱数据列表
    /// </summary>
    private Dictionary<int, TreasureChestData> m_pTreasureChests = new Dictionary<int, TreasureChestData>();

    public TreasureSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }
    public override string GetSqlTableName() => SqlTableName.role_treasurechestinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_nTreasureChestIndex = Convert.ToInt32(dataRow["treasurechestindex"]);
            string treasurechestinfo = Convert.ToString(dataRow["treasurechestinfo"]);
            if (treasurechestinfo != null)
            {
                List<List<object>> treasurechestinfos = UtilityMethod.JsonDeserializeObject<List<List<object>>>(treasurechestinfo);
                if (treasurechestinfos != null)
                {
                    for (int i = 0; i < treasurechestinfos.Count; i++)
                    {
                        List<object> treasureChestDataList = treasurechestinfos[i];
                        TreasureChestData treasureChestData = new TreasureChestData();
                        treasureChestData.instId = Convert.ToInt32(treasureChestDataList[TreasureChestData.instIdIdx]);
                        treasureChestData.cfgId = Convert.ToInt32(treasureChestDataList[TreasureChestData.cfgIdIdx]);
                        treasureChestData.treasureChestSourceEnum = (TreasureChestSourceEnum)Convert.ToInt32(treasureChestDataList[TreasureChestData.treasureChestSourceEnumIdx]);
                        treasureChestData.orderHash = Convert.ToString(treasureChestDataList[TreasureChestData.orderHashIdx]);
                        treasureChestData.isVerified = Convert.ToInt32(treasureChestDataList[TreasureChestData.isVerifiedIdx]) == 1;
                        treasureChestData.relationChains = ((JArray)treasureChestDataList[TreasureChestData.relationChainsIdx]).ToObject<List<int>>();
                        treasureChestData.isConsume = Convert.ToInt32(treasureChestDataList[TreasureChestData.isConsumeIdx]) == 1;
                        treasureChestData.isOpen = Convert.ToInt32(treasureChestDataList[TreasureChestData.isOpenIdx]) == 1;
                        treasureChestData.score = Convert.ToInt32(treasureChestDataList[TreasureChestData.scoreIdx]);
                        m_pTreasureChests.Add(treasureChestData.instId, treasureChestData);
                    }
                }
            }
        }
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyTreasureChestSystem resMsgBodyTreasureChestSystem = new ResMsgBodyTreasureChestSystem();
        foreach (var item in m_pTreasureChests)
        {
            if (!item.Value.isConsume && !item.Value.isOpen)
            {
                ResTreasureChestData resTreasureChestData = GetClientTreasureChestData(item.Value);
                resMsgBodyTreasureChestSystem.TreasureChests.Add(resTreasureChestData);
            }
        }
        return resMsgBodyTreasureChestSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();

        List<List<object>> treasureChestInfo = new List<List<object>>();
        foreach (var item in m_pTreasureChests)
        {
            List<object> info = GetTreasureChestData(item.Value);
            treasureChestInfo.Add(info);
        }

        AddSaveCache("treasurechestindex", m_nTreasureChestIndex);
        AddSaveCache("treasurechestinfo", UtilityMethod.JsonSerializeObject(treasureChestInfo));
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取宝箱
    /// </summary>
    /// <param name="i_nInstId"></param>
    /// <returns></returns>
    public TreasureChestData GetTreasureChestData(int i_nInstId)
    {
        m_pTreasureChests.TryGetValue(i_nInstId, out TreasureChestData treasureChestData);
        return treasureChestData;
    }

    /// <summary>
    /// 获取宝箱
    /// </summary>
    /// <param name="i_nInstId"></param>
    /// <returns></returns>
    public List<object> GetTreasureChestData(TreasureChestData i_pTreasureChestData)
    {
        List<object> info = new List<object>()
                {
                    i_pTreasureChestData.instId,
                    i_pTreasureChestData.cfgId,
                    i_pTreasureChestData.treasureChestSourceEnum,
                    i_pTreasureChestData.orderHash,
                    i_pTreasureChestData.isVerified ? 1 : 0,
                    i_pTreasureChestData.relationChains,
                    i_pTreasureChestData.isConsume? 1 : 0,
                    i_pTreasureChestData.isOpen? 1 : 0,
                    i_pTreasureChestData.score,
                };
        return info;
    }

    /// <summary>
    /// 获取客户端所需宝箱数据
    /// </summary>
    /// <param name="i_nInstId"></param>
    /// <returns></returns>
    public ResTreasureChestData GetClientTreasureChestData(TreasureChestData i_pTreasureChestData)
    {
        ResTreasureChestData resTreasureChestData = new ResTreasureChestData()
        {
            InstId = i_pTreasureChestData.instId,
            CfgId = i_pTreasureChestData.cfgId,
            TreasureChestSource = i_pTreasureChestData.treasureChestSourceEnum,
            OrderHash = i_pTreasureChestData.orderHash,
            IsVerified = i_pTreasureChestData.isVerified,
        };
        return resTreasureChestData;
    }

    /// <summary>
    /// 创建宝箱
    /// </summary>
    /// <param name="i_nTreasureChestCfgId"></param>
    /// <param name="i_sOrderHash"></param>
    /// <param name="i_tRelationChains"></param>
    /// <returns></returns>
    public TreasureChestData CreateTreasureChestData(int i_nTreasureChestCfgId, TreasureChestSourceEnum i_eTreasureChestSourceEnum, string i_sOrderHash = "", List<int> i_tRelationChains = default)
    {
        int instId = ++m_nTreasureChestIndex;
        TreasureChestData treasureChestData = new TreasureChestData()
        {
            instId = instId,
            cfgId = i_nTreasureChestCfgId,
            treasureChestSourceEnum = i_eTreasureChestSourceEnum,
            orderHash = i_sOrderHash,
            isVerified = true, // i_eTreasureChestSourceEnum != TreasureChestSourceEnum.eBuy,
            relationChains = i_tRelationChains == default ? new List<int>() : i_tRelationChains,
            isConsume = false,
            isOpen = false,
            score = 0,
            time = UtilityMethod.GetUnixTimeMilliseconds(),
        };

        m_pTreasureChests.Add(instId, treasureChestData);

        OnChangeData();
        return treasureChestData;
    }

    /// <summary>
    /// 添加宝箱
    /// </summary>
    /// <param name="i_nTreasureChestCfgId"></param>
    /// <param name="i_eTreasureChestSourceEnum"></param>
    /// <param name="i_nAddNum"></param>
    public void AddTreasureChest(int i_nTreasureChestCfgId, TreasureChestSourceEnum i_eTreasureChestSourceEnum, int i_nAddNum)
    {
        for (int i = 0; i < i_nAddNum; i++)
        {
            CreateTreasureChestData(i_nTreasureChestCfgId, i_eTreasureChestSourceEnum);
        }
    }

    /// <summary>
    /// 购买宝箱
    /// </summary>
    /// <param name="i_nTreasureChestCfgId"></param>
    /// <param name="i_sOrderHash"></param>
    /// <returns></returns>
    public void BuyTreasureChest(int i_nTreasureChestCfgId, string i_sOrderHash, int i_nBuyNum)
    {
        List<int> treasureChestDatas = new List<int>();
        for (int i = 0; i < i_nBuyNum; i++)
        {
            TreasureChestData treasureChestData = CreateTreasureChestData(i_nTreasureChestCfgId, TreasureChestSourceEnum.Buy, i_sOrderHash);
            treasureChestDatas.Add(treasureChestData.instId);
        }
        // todo 提交订单
        //OrderManager.Instance.AddOrderData(i_sOrderHash, this.GetPlayer().GetRoleId(), this.GetPlayer().GetAccount(), OrderTypeEnum.eTreasure, treasureChestDatas);
    }

    /// <summary>
    /// 融合宝箱
    /// </summary>
    /// <param name="i_tFusionTreasureChests"></param>
    public bool FusionTreasureChest(List<int> i_tFusionTreasureChests)
    {
        if (i_tFusionTreasureChests == null || i_tFusionTreasureChests.Count == 0)
        {
            return false;
        }

        List<int> distinctList = i_tFusionTreasureChests.Distinct().ToList();
        if (distinctList.Count != i_tFusionTreasureChests.Count)
        {
            return false;
        }

        TreasureChestData treasureChestData0 = this.GetTreasureChestData(i_tFusionTreasureChests[0]);
        if (treasureChestData0 == null)
        {
            return false;
        }

        TreasureChest_Data treasureChest_Data0 = ConfigManager.TreasureChest.Get(treasureChestData0.cfgId);
        if (treasureChest_Data0 == null || treasureChest_Data0.FusionParam == null || treasureChest_Data0.FusionParam.Length == 0)
        {
            return false;
        }
        int nextCfgId = treasureChest_Data0.FusionParam[0];
        int consumeNum = treasureChest_Data0.FusionParam[1];

        if (i_tFusionTreasureChests.Count < consumeNum)
        {
            return false;
        }

        for (int i = 1; i < i_tFusionTreasureChests.Count; i++)
        {
            TreasureChestData treasureChestData = this.GetTreasureChestData(i_tFusionTreasureChests[i]);
            if (treasureChestData == null || treasureChestData.cfgId != treasureChestData0.cfgId || !treasureChestData.isVerified || treasureChestData.isConsume || treasureChestData.isOpen)
            {
                return false;
            }
        }

        foreach (var item in i_tFusionTreasureChests)
        {
            TreasureChestData treasureChestData = this.GetTreasureChestData(item);
            treasureChestData.isConsume = true;
        }
        TreasureChestData treasureChestData1 = CreateTreasureChestData(nextCfgId, TreasureChestSourceEnum.Fusion, "", i_tFusionTreasureChests);
        return true;
    }

    /// <summary>
    /// 宝箱验证通过
    /// </summary>
    /// <param name="i_nInstId"></param>
    public void TreasureChestVerified(int i_nInstId)
    {
        TreasureChestData treasureChestData = this.GetTreasureChestData(i_nInstId);
        if (treasureChestData == null)
        {
            return;
        }

        if (treasureChestData.isVerified)
        {
            return;
        }
        treasureChestData.isVerified = true;

        OnChangeData();
    }

    /// <summary>
    /// 打开宝箱
    /// </summary>
    /// <param name="i_nInstId"></param>
    public void OpenTreasureChest(int i_nInstId)
    {
        TreasureChestData treasureChestData = this.GetTreasureChestData(i_nInstId);
        if (treasureChestData == null)
        {
            return;
        }

        if (!treasureChestData.isVerified || treasureChestData.isConsume || treasureChestData.isOpen)
        {
            return;
        }

        TreasureChest_Data treasureChest_Data = ConfigManager.TreasureChest.Get(treasureChestData.cfgId);
        if (treasureChest_Data.RandomScore.Length == 2)
        {
            treasureChestData.score = Random.Shared.Next(treasureChest_Data.RandomScore[0], treasureChest_Data.RandomScore[1] + 1);
        }
        treasureChestData.isOpen = true;

        OnChangeData();
    }

    /// <summary>
    /// 获取至今已开启宝箱总积分
    /// </summary>
    /// <returns></returns>
    public int GetTotalScore()
    {
        int score = 0;
        foreach (var item in m_pTreasureChests)
        {
            TreasureChestData treasureChestData = item.Value;
            if (treasureChestData.isVerified && treasureChestData.isOpen && !treasureChestData.isConsume)
            {
                score += treasureChestData.score;
            }
        }
        return score;
    }
}

/// <summary>
/// 宝箱数据
/// </summary>
public class TreasureChestData
{
    /// <summary>
    /// 实例Id
    /// </summary>
    public int instId;
    public static int instIdIdx = 0;
    /// <summary>
    /// 宝箱配置Id
    /// </summary>
    public int cfgId;
    public static int cfgIdIdx = 1;
    /// <summary>
    /// 宝箱来源
    /// </summary>
    public TreasureChestSourceEnum treasureChestSourceEnum;
    public static int treasureChestSourceEnumIdx = 2;
    /// <summary>
    /// 订单Hash
    /// </summary>
    public string orderHash;
    public static int orderHashIdx = 3;
    /// <summary>
    /// 是否已验证通过
    /// </summary>
    public bool isVerified;
    public static int isVerifiedIdx = 4;
    /// <summary>
    /// 合成关系链
    /// </summary>
    public List<int> relationChains;
    public static int relationChainsIdx = 5;
    /// <summary>
    /// 是否已合成消耗
    /// </summary>
    public bool isConsume;
    public static int isConsumeIdx = 6;
    /// <summary>
    /// 是否已打开
    /// </summary>
    public bool isOpen;
    public static int isOpenIdx = 7;
    /// <summary>
    /// 分数
    /// </summary>
    public int score;
    public static int scoreIdx = 8;
    /// <summary>
    /// 获取时间
    /// </summary>
    public long time;
    public static int timeIdx = 9;
}