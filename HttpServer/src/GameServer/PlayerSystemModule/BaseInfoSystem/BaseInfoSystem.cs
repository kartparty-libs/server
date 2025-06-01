using Google.Protobuf;
using Proto;
using System.Data;

/// <summary>
/// 基础信息系统
/// </summary>
public class BaseInfoSystem : BasePlayerSystem
{
    /// <summary>
    /// 玩家基础信息
    /// </summary>
    protected PlayerBaseInfo m_pPlayerBaseInfo = new PlayerBaseInfo();

    public BaseInfoSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }

    public override string GetSqlTableName() => SqlTableName.role_baseinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_pPlayerBaseInfo.headId = Convert.ToInt32(dataRow["headid"]);
            m_pPlayerBaseInfo.gold = Convert.ToInt64(dataRow["gold"]);
            m_pPlayerBaseInfo.diamond = Convert.ToInt64(dataRow["diamond"]);
            m_pPlayerBaseInfo.cultivateGold = Convert.ToInt64(dataRow["cultivategold"]);
            m_pPlayerBaseInfo.tokenScore = Convert.ToInt64(dataRow["tokenScore"]);
            m_pPlayerBaseInfo.monetary = Convert.ToInt64(dataRow["monetary"]);
            m_pPlayerBaseInfo.roleCfgId = Convert.ToInt32(dataRow["rolecfgid"]);
            m_pPlayerBaseInfo.carCfgId = Convert.ToInt32(dataRow["carcfgid"]);
            m_pPlayerBaseInfo.totalReceiveToken = Convert.ToInt32(dataRow["totalreceivetoken"]);
            m_pPlayerBaseInfo.USDT = Convert.ToInt32(dataRow["usdt"]);
            m_pPlayerBaseInfo.TON = Convert.ToInt32(dataRow["ton"]);
        }
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyBaseInfo resMsgBodyBaseInfo = new ResMsgBodyBaseInfo();
        resMsgBodyBaseInfo.HeadId = GetHeadId();
        resMsgBodyBaseInfo.Gold = GetGold();
        resMsgBodyBaseInfo.Diamond = GetDiamond();
        resMsgBodyBaseInfo.CultivateGold = GetCultivateGold();
        resMsgBodyBaseInfo.TokenScore = GetTokenScore();
        resMsgBodyBaseInfo.Monetary = GetMonetary();
        resMsgBodyBaseInfo.RoleCfgId = GetRoleCfgId();
        resMsgBodyBaseInfo.CarCfgId = GetCarCfgId();
        resMsgBodyBaseInfo.TotalReceiveToken = GetTotalReceiveToken();
        resMsgBodyBaseInfo.USDT = GetUSDT();
        resMsgBodyBaseInfo.TON = GetTON();
        return resMsgBodyBaseInfo;
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 头像

    /// <summary>
    /// 获取玩家头像Id
    /// </summary>
    /// <returns></returns>
    public int GetHeadId()
    {
        return m_pPlayerBaseInfo.headId;
    }

    /// <summary>
    /// 设置玩家头像Id
    /// </summary>
    /// <param name="i_nHeadId"></param>
    public void SetHeadId(int i_nHeadId)
    {
        m_pPlayerBaseInfo.headId = i_nHeadId;
        AddSaveCache("headid", i_nHeadId);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 金币

    /// <summary>
    /// 获取玩家金币
    /// </summary>
    /// <returns></returns>
    public long GetGold()
    {
        return m_pPlayerBaseInfo.gold;
    }

    /// <summary>
    /// 添加玩家金币
    /// </summary>
    /// <param name="i_nGold"></param>
    public void AddGold(long i_nGold)
    {
        if (i_nGold <= 0)
        {
            return;
        }
        SetGold(m_pPlayerBaseInfo.gold + i_nGold);
    }

    /// <summary>
    /// 是否足够消耗金币
    /// </summary>
    /// <param name="i_nGold"></param>
    /// <returns></returns>
    public bool IsCostGold(long i_nGold)
    {
        if (i_nGold < 0 || m_pPlayerBaseInfo.gold < i_nGold)
        {
            return false;
        }
        return true;
    }

    /// <summary>
    /// 消耗金币
    /// </summary>
    /// <param name="i_nGold"></param>
    /// <returns></returns>
    public bool CostGold(long i_nGold)
    {
        if (!IsCostGold(i_nGold))
        {
            return false;
        }

        SetGold(m_pPlayerBaseInfo.gold - i_nGold);

        this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent201, i_nGold);
        return true;
    }

    /// <summary>
    /// 设置玩家金币
    /// </summary>
    /// <param name="i_nGold"></param>
    public void SetGold(long i_nGold)
    {
        m_pPlayerBaseInfo.gold = i_nGold;
        AddSaveCache("gold", i_nGold);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 钻石

    /// <summary>
    /// 获取玩家钻石
    /// </summary>
    /// <returns></returns>
    public long GetDiamond()
    {
        return m_pPlayerBaseInfo.diamond;
    }

    /// <summary>
    /// 添加玩家钻石
    /// </summary>
    /// <param name="i_nDiamond"></param>
    public void AddDiamond(long i_nDiamond)
    {
        if (i_nDiamond <= 0)
        {
            return;
        }
        SetDiamond(m_pPlayerBaseInfo.diamond + i_nDiamond);
    }

    /// <summary>
    /// 是否足够消耗钻石
    /// </summary>
    /// <param name="i_nDiamond"></param>
    /// <returns></returns>
    public bool IsCostDiamond(long i_nDiamond)
    {
        if (i_nDiamond < 0 || m_pPlayerBaseInfo.diamond < i_nDiamond)
        {
            return false;
        }
        return true;
    }

    /// <summary>
    /// 消耗钻石
    /// </summary>
    /// <param name="i_nDiamond"></param>
    /// <returns></returns>
    public bool CostDiamond(long i_nDiamond)
    {
        if (!IsCostDiamond(i_nDiamond))
        {
            return false;
        }

        SetDiamond(m_pPlayerBaseInfo.diamond - i_nDiamond);

        this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent204, i_nDiamond);
        return true;
    }

    /// <summary>
    /// 设置玩家钻石
    /// </summary>
    /// <param name="i_nDiamond"></param>
    public void SetDiamond(long i_nDiamond)
    {
        m_pPlayerBaseInfo.diamond = i_nDiamond;
        AddSaveCache("diamond", i_nDiamond);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 养成收益累计金币

    /// <summary>
    /// 获取玩家养成收益累计金币
    /// </summary>
    /// <returns></returns>
    public long GetCultivateGold()
    {
        return m_pPlayerBaseInfo.cultivateGold;
    }

    /// <summary>
    /// 添加玩家养成收益累计金币
    /// </summary>
    /// <param name="i_nCultivateGold"></param>
    public void AddCultivateGold(long i_nCultivateGold)
    {
        if (i_nCultivateGold <= 0)
        {
            return;
        }
        SetCultivateGold(m_pPlayerBaseInfo.cultivateGold + i_nCultivateGold);
    }

    /// <summary>
    /// 设置玩家养成收益累计金币
    /// </summary>
    /// <param name="i_nCultivateGold"></param>
    public void SetCultivateGold(long i_nCultivateGold)
    {
        m_pPlayerBaseInfo.cultivateGold = i_nCultivateGold;
        AddSaveCache("cultivategold", i_nCultivateGold);

        //RankManager.Instance.OnChangeRankValue(RankTypeEnum.GoldEarnings, this.GetPlayer().GetRoleId(), m_pPlayerBaseInfo.cultivateGold, this.GetPlayer());
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // token积分(k币)

    /// <summary>
    /// 获取玩家token积分(k币)
    /// </summary>
    /// <returns></returns>
    public long GetTokenScore()
    {
        return m_pPlayerBaseInfo.tokenScore;
    }

    /// <summary>
    /// 添加玩家token积分(k币)
    /// </summary>
    /// <param name="i_nTokenScore"></param>
    public void AddTokenScore(long i_nTokenScore)
    {
        if (i_nTokenScore <= 0)
        {
            return;
        }
        SetTokenScore(m_pPlayerBaseInfo.tokenScore + i_nTokenScore);
    }

    /// <summary>
    /// 消耗token积分(k币)
    /// </summary>
    /// <param name="i_nTokenScore"></param>
    /// <returns></returns>
    public bool CostTokenScore(long i_nTokenScore)
    {
        if (i_nTokenScore < 0 || m_pPlayerBaseInfo.tokenScore < i_nTokenScore)
        {
            return false;
        }

        SetTokenScore(m_pPlayerBaseInfo.tokenScore - i_nTokenScore);
        return true;
    }

    /// <summary>
    /// 设置玩家token积分(k币)
    /// </summary>
    /// <param name="i_nTokenScore"></param>
    public void SetTokenScore(long i_nTokenScore)
    {
        m_pPlayerBaseInfo.tokenScore = i_nTokenScore;
        AddSaveCache("tokenScore", i_nTokenScore);

        //RankManager.Instance.OnChangeRankValue(RankTypeEnum.MiningTokenScore, this.GetPlayer().GetRoleId(), GetTokenScore(), this.GetPlayer());
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 消费金额/美金

    /// <summary>
    /// 获取玩家消费金额/美金 扩大1000
    /// </summary>
    /// <returns></returns>
    public long GetMonetary()
    {
        return m_pPlayerBaseInfo.monetary;
    }

    /// <summary>
    /// 添加玩家消费金额/美金 扩大1000
    /// </summary>
    /// <param name="i_nMonetary"></param>
    public void AddMonetary(long i_nMonetary)
    {
        if (i_nMonetary <= 0)
        {
            return;
        }
        SetMonetary(m_pPlayerBaseInfo.monetary + i_nMonetary);
    }

    /// <summary>
    /// 设置玩家消费金额/美金 扩大1000
    /// </summary>
    /// <param name="i_nMonetary"></param>
    public void SetMonetary(long i_nMonetary)
    {
        m_pPlayerBaseInfo.monetary = i_nMonetary;
        AddSaveCache("monetary", i_nMonetary);

        this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent112, m_pPlayerBaseInfo.monetary);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 角色配置Id

    /// <summary>
    /// 获取角色配置Id
    /// </summary>
    /// <returns></returns>
    public int GetRoleCfgId()
    {
        return m_pPlayerBaseInfo.roleCfgId;
    }

    /// <summary>
    /// 设置角色配置Id
    /// </summary>
    /// <param name="i_nRoleCfgId"></param>
    public void SetRoleCfgId(int i_nRoleCfgId)
    {
        m_pPlayerBaseInfo.roleCfgId = i_nRoleCfgId;
        AddSaveCache("rolecfgid", i_nRoleCfgId);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 赛车配置Id

    /// <summary>
    /// 获取赛车配置Id
    /// </summary>
    /// <returns></returns>
    public int GetCarCfgId()
    {
        return m_pPlayerBaseInfo.carCfgId;
    }

    /// <summary>
    /// 设置赛车配置Id
    /// </summary>
    /// <param name="i_nCarCfgId"></param>
    public void SetCarCfgId(int i_nCarCfgId)
    {
        m_pPlayerBaseInfo.carCfgId = i_nCarCfgId;
        AddSaveCache("carcfgid", i_nCarCfgId);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 总领取token数(k币)

    /// <summary>
    /// 获取玩家总领取token数(k币)
    /// </summary>
    /// <returns></returns>
    public long GetTotalReceiveToken()
    {
        return m_pPlayerBaseInfo.totalReceiveToken;
    }

    /// <summary>
    /// 添加玩家总领取token数(k币)
    /// </summary>
    /// <param name="i_nTotalReceiveToken"></param>
    public void AddTotalReceiveToken(long i_nTotalReceiveToken)
    {
        if (i_nTotalReceiveToken <= 0)
        {
            return;
        }
        SetTotalReceiveToken(m_pPlayerBaseInfo.totalReceiveToken + i_nTotalReceiveToken);
    }

    /// <summary>
    /// 设置玩家总领取token数(k币)
    /// </summary>
    /// <param name="i_nTotalReceiveToken"></param>
    public void SetTotalReceiveToken(long i_nTotalReceiveToken)
    {
        m_pPlayerBaseInfo.totalReceiveToken = i_nTotalReceiveToken;
        AddSaveCache("totalreceivetoken", i_nTotalReceiveToken);
    }
    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 消费USDT记录

    /// <summary>
    /// 获取消费USDT记录
    /// </summary>
    /// <returns></returns>
    public long GetUSDT()
    {
        return m_pPlayerBaseInfo.USDT;
    }

    /// <summary>
    /// 添加消费USDT记录
    /// </summary>
    /// <param name="i_nUSDT"></param>
    public void AddUSDT(long i_nUSDT)
    {
        if (i_nUSDT <= 0)
        {
            return;
        }
        SetUSDT(m_pPlayerBaseInfo.USDT + i_nUSDT);
    }

    /// <summary>
    /// 设置消费USDT记录
    /// </summary>
    /// <param name="i_nUSDT"></param>
    public void SetUSDT(long i_nUSDT)
    {
        m_pPlayerBaseInfo.USDT = i_nUSDT;
        AddSaveCache("usdt", i_nUSDT);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------
    // 消费TON记录

    /// <summary>
    /// 获取消费TON记录
    /// </summary>
    /// <returns></returns>
    public long GetTON()
    {
        return m_pPlayerBaseInfo.TON;
    }

    /// <summary>
    /// 添加消费TON记录
    /// </summary>
    /// <param name="i_nTON"></param>
    public void AddTON(long i_nTON)
    {
        if (i_nTON <= 0)
        {
            return;
        }
        SetTON(m_pPlayerBaseInfo.TON + i_nTON);
    }

    /// <summary>
    /// 设置消费TON记录
    /// </summary>
    /// <param name="i_nTON"></param>
    public void SetTON(long i_nTON)
    {
        m_pPlayerBaseInfo.TON = i_nTON;
        AddSaveCache("ton", i_nTON);
    }
}

/// <summary>
/// 玩家基础信息
/// </summary>
public class PlayerBaseInfo()
{
    /// <summary>
    /// 头像Id
    /// </summary>
    public int headId = 1;
    /// <summary>
    /// 金币
    /// </summary>
    public long gold = 0;
    /// <summary>
    /// 钻石
    /// </summary>
    public long diamond = 0;
    /// <summary>
    /// 养成收益累计金币
    /// </summary>
    public long cultivateGold = 0;
    /// <summary>
    /// token积分
    /// </summary>
    public long tokenScore = 0;
    /// <summary>
    /// 消费金额/美金 扩大1000
    /// </summary>
    public long monetary = 0;
    /// <summary>
    /// 角色配置Id
    /// </summary>
    public int roleCfgId = 1;
    /// <summary>
    /// 赛车配置Id
    /// </summary>
    public int carCfgId = 1;
    /// <summary>
    /// 总领取token数(k币)
    /// </summary>
    public long totalReceiveToken = 1;
    /// <summary>
    /// 消费USDT记录
    /// </summary>
    public long USDT = 0;
    /// <summary>
    /// 消费TON记录
    /// </summary>
    public long TON = 0;
}