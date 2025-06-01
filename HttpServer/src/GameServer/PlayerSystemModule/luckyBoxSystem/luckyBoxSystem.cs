using Google.Protobuf;
using Proto;
using System.Data;

/// <summary>
/// 幸运宝箱系统
/// </summary>
public class LuckyBoxSystem : BasePlayerSystem
{
    /// <summary>
    /// 幸运宝箱数据列表
    /// </summary>
    protected List<LuckyBoxData> m_tLuckyBoxDatas = new List<LuckyBoxData>();

    /// <summary>
    /// 最新开的幸运宝箱数据列表
    /// </summary>
    protected List<LuckyBoxData> m_tNewLuckyBoxDatas = new List<LuckyBoxData>();

    /// <summary>
    /// 最大幸运分
    /// </summary>
    protected int m_nMaxLuckyScroe = 0;

    public LuckyBoxSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }

    public override string GetSqlTableName() => SqlTableName.role_luckyboxinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_nMaxLuckyScroe = Convert.ToInt32(dataRow["maxluckyscroe"]);
        }
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyLuckyBoxSystem resMsgBodyLuckyBoxSystem = new ResMsgBodyLuckyBoxSystem();
        resMsgBodyLuckyBoxSystem.MaxLuckyScroe = m_nMaxLuckyScroe;
        foreach (var item in m_tNewLuckyBoxDatas)
        {
            ResLuckyBoxData resLuckyBoxData = new ResLuckyBoxData();
            resLuckyBoxData.LuckyBoxCfgId = item.luckyBoxCfgId;
            resLuckyBoxData.RandomValue = item.randomValue;
            resLuckyBoxData.LuckyScore = item.luckyScore;
            resLuckyBoxData.Time = item.time;
            resMsgBodyLuckyBoxSystem.LuckyBoxDatas.Add(resLuckyBoxData);
        }
        m_tNewLuckyBoxDatas.Clear();
        return resMsgBodyLuckyBoxSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();
        AddSaveCache("maxluckyscroe", m_nMaxLuckyScroe);
    }
    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 创建幸运宝箱
    /// </summary>
    /// <param name="i_nLuckyBoxCfgId"></param>
    /// <returns></returns>
    public LuckyBoxData CreateLuckyBox(int i_nLuckyBoxCfgId)
    {
        LuckyBox_Data luckyBox_Data = ConfigManager.LuckyBox.Get(i_nLuckyBoxCfgId);
        if (luckyBox_Data == null)
        {
            return null;
        }
        LuckyBoxData luckyBoxData = new LuckyBoxData();
        luckyBoxData.luckyBoxCfgId = i_nLuckyBoxCfgId;
        luckyBoxData.time = UtilityMethod.GetUnixTimeMilliseconds();

        int random = Random.Shared.Next(luckyBox_Data.RandomValue[0], luckyBox_Data.RandomValue[1]);
        luckyBoxData.luckyScore = random * luckyBox_Data.LuckyRate;
        if (luckyBoxData.luckyScore > m_nMaxLuckyScroe)
        {
            m_nMaxLuckyScroe = luckyBoxData.luckyScore;
        }

        luckyBoxData.randomValue = random;
        this.GetSystem<ItemSystem>().AddItem(luckyBox_Data.ItemId, luckyBoxData.randomValue);

        Debug.Instance.Log($"LuckyBoxSystem CreateLuckyBox -> RoleId({this.GetPlayer().GetRoleId()}) LuckyBoxCfgId({i_nLuckyBoxCfgId}) RandomValue({luckyBoxData.randomValue})", LogType.system);

        OnChangeData();

        this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent116, 1);
        this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent203, 1);

        return luckyBoxData;
    }

    /// <summary>
    /// 打开幸运宝箱
    /// </summary>
    /// <param name="i_nOpenCount"></param>
    /// <returns></returns>
    public bool OpenLuckyBox(int i_nOpenCount)
    {
        int cost = i_nOpenCount * ConfigManager.Param.Get("LuckyBoxOpenCost").IntParam;
        if (!this.GetSystem<BaseInfoSystem>().CostDiamond(cost))
        {
            return false;
        }

        for (int i = 0; i < i_nOpenCount; i++)
        {
            int randomWeight = Random.Shared.Next(1, LuckyBox_Table.TotalWeight + 1);
            for (int j = 0; j < ConfigManager.LuckyBox.Count; j++)
            {
                LuckyBox_Data luckyBox_Data = ConfigManager.LuckyBox.GetItem(j);
                randomWeight -= luckyBox_Data.Weight;
                if (randomWeight <= 0)
                {
                    m_tNewLuckyBoxDatas.Add(CreateLuckyBox(luckyBox_Data.Id));
                    break;
                }
            }
        }
        return true;
    }
}

/// <summary>
/// 幸运宝箱数据
/// </summary>
public class LuckyBoxData()
{
    /// <summary>
    /// 配置Id
    /// </summary>
    public int luckyBoxCfgId;
    /// <summary>
    /// 随机值
    /// </summary>
    public long randomValue;
    /// <summary>
    /// 获得时间
    /// </summary>
    public long time;
    /// <summary>
    /// 幸运分
    /// </summary>
    public int luckyScore;
}