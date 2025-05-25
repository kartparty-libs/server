using Google.Protobuf;
using Proto;
using System.Data;

/// <summary>
/// 挖矿系统
/// </summary>
public class MiningSystem : BasePlayerSystem
{
    /// <summary>
    /// 积分系数/分钟 扩大倍率
    /// </summary>
    protected const int ScoreCoefficientValue = 100000;

    /// <summary>
    /// 赛车挖矿质押数据
    /// </summary>
    protected MiningData m_pCarMiningData = new MiningData();

    /// <summary>
    /// 赛车挖矿待预结算质押数据列表
    /// </summary>
    protected LinkedList<MiningData> m_tCarMiningDatas = new LinkedList<MiningData>();

    /// <summary>
    /// 赛车挖矿上次预结算截止时间
    /// </summary>
    protected long m_nCarLastPreSettlementTime = 0;

    /// <summary>
    /// 赛车挖矿预结算的token积分
    /// </summary>
    protected long m_nCarPreSettlementTokenScore = 0;

    /// <summary>
    /// 赛车挖矿已结算的token积分
    /// </summary>
    protected long m_nCarSettlementTokenScore = 0;

    /// <summary>
    /// 钻石挖矿质押数据
    /// </summary>
    protected MiningData m_pDiamondMiningData = new MiningData();

    /// <summary>
    /// 钻石挖矿待预结算质押数据列表
    /// </summary>
    protected LinkedList<MiningData> m_tDiamondMiningDatas = new LinkedList<MiningData>();

    /// <summary>
    /// 钻石挖矿上次预结算截止时间
    /// </summary>
    protected long m_nDiamondLastPreSettlementTime = 0;

    /// <summary>
    /// 钻石挖矿预结算的token积分
    /// </summary>
    protected long m_nDiamondPreSettlementTokenScore = 0;

    /// <summary>
    /// 钻石挖矿已结算的token积分
    /// </summary>
    protected long m_nDiamondSettlementTokenScore = 0;

    public MiningSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }

    public override string GetSqlTableName() => SqlTableName.role_mininginfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_nCarLastPreSettlementTime = Convert.ToInt64(dataRow["carlastpresettlementtime"]);
            m_nCarPreSettlementTokenScore = Convert.ToInt64(dataRow["carpresettlementtokenscore"]);
            m_nCarSettlementTokenScore = Convert.ToInt64(dataRow["carsettlementtokenscore"]);

            m_nDiamondLastPreSettlementTime = Convert.ToInt64(dataRow["diamondlastpresettlementtime"]);
            m_nDiamondPreSettlementTokenScore = Convert.ToInt64(dataRow["diamondpresettlementtokenscore"]);
            m_nDiamondSettlementTokenScore = Convert.ToInt64(dataRow["diamondsettlementtokenscore"]);

            string carminingdata = Convert.ToString(dataRow["carminingdata"]);
            string carminingdatas = Convert.ToString(dataRow["carminingdatas"]);
            string diamondminingdata = Convert.ToString(dataRow["diamondminingdata"]);
            string diamondminingdatas = Convert.ToString(dataRow["diamondminingdatas"]);
            var carMiningData = UtilityMethod.JsonDeserializeObject<MiningData>(carminingdata);
            if (carMiningData != null)
            {
                m_pCarMiningData = carMiningData;
            }
            var carMiningDatas = UtilityMethod.JsonDeserializeObject<LinkedList<MiningData>>(carminingdatas);
            if (carMiningDatas != null)
            {
                m_tCarMiningDatas = carMiningDatas;
            }
            var diamondMiningData = UtilityMethod.JsonDeserializeObject<MiningData>(diamondminingdata);
            if (diamondMiningData != null)
            {
                m_pDiamondMiningData = diamondMiningData;
            }
            var diamondMiningDatas = UtilityMethod.JsonDeserializeObject<LinkedList<MiningData>>(diamondminingdatas);
            if (diamondMiningDatas != null)
            {
                m_tDiamondMiningDatas = diamondMiningDatas;
            }
        }
    }

    //public override void DayRefresh()
    //{
    //    base.DayRefresh();
    //    // 2测不清
    //    m_tCarMiningDatas.Clear();
    //    m_tDiamondMiningDatas.Clear();
    //    OnChangeData();
    //}

    public override void OnHandle(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        base.OnHandle(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);
        CarPreSettlementTokenScore(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);
        DiamondPreSettlementTokenScore(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = true;

        ResMsgBodyMiningSystem resMsgBodyMiningSystem = new ResMsgBodyMiningSystem();
        resMsgBodyMiningSystem.CarTokenScorePoolValue = MiningManager.Instance.GetCarTokenScorePoolValue();
        resMsgBodyMiningSystem.DiamondTokenScorePoolValue = MiningManager.Instance.GetDiamondTokenScorePoolValue();

        resMsgBodyMiningSystem.CarLevel = m_pCarMiningData.value;
        resMsgBodyMiningSystem.CarLastChangeTime = m_pCarMiningData.time;
        resMsgBodyMiningSystem.CarPreSettlementTokenScore = m_nCarPreSettlementTokenScore / ScoreCoefficientValue;
        resMsgBodyMiningSystem.CarSettlementTokenScore = m_nCarSettlementTokenScore;
        resMsgBodyMiningSystem.CarLastPreSettlementTime = m_nCarLastPreSettlementTime;
        resMsgBodyMiningSystem.CarTotalMiningCount = MiningManager.Instance.GetAllServerCarTotalMiningCount();
        resMsgBodyMiningSystem.CarTotalMiningValue = MiningManager.Instance.GetAllServerCarTotalMiningValue();

        resMsgBodyMiningSystem.DiamondValue = m_pDiamondMiningData.value;
        resMsgBodyMiningSystem.DiamondLastChangeTime = m_pDiamondMiningData.time;
        resMsgBodyMiningSystem.DiamondPreSettlementTokenScore = m_nDiamondPreSettlementTokenScore / ScoreCoefficientValue;
        resMsgBodyMiningSystem.DiamondSettlementTokenScore = m_nDiamondSettlementTokenScore;
        resMsgBodyMiningSystem.DiamondLastPreSettlementTime = m_nDiamondLastPreSettlementTime;
        resMsgBodyMiningSystem.DiamondTotalMiningCount = MiningManager.Instance.GetAllServerDiamondTotalMiningCount();
        resMsgBodyMiningSystem.DiamondTotalMiningValue = MiningManager.Instance.GetAllServerDiamondTotalMiningValue();

        resMsgBodyMiningSystem.MiningOpenTime = Param_Table.MiningOpenTime;
        resMsgBodyMiningSystem.MiningCloseTime = Param_Table.MiningCloseTime;
        return resMsgBodyMiningSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();

        AddSaveCache("carminingdata", UtilityMethod.JsonSerializeObject(m_pCarMiningData));
        AddSaveCache("carminingdatas", UtilityMethod.JsonSerializeObject(m_tCarMiningDatas));
        AddSaveCache("carlastpresettlementtime", m_nCarLastPreSettlementTime);
        AddSaveCache("carpresettlementtokenscore", m_nCarPreSettlementTokenScore);
        AddSaveCache("carsettlementtokenscore", m_nCarSettlementTokenScore);

        AddSaveCache("diamondminingdata", UtilityMethod.JsonSerializeObject(m_pDiamondMiningData));
        AddSaveCache("diamondminingdatas", UtilityMethod.JsonSerializeObject(m_tDiamondMiningDatas));
        AddSaveCache("diamondlastpresettlementtime", m_nDiamondLastPreSettlementTime);
        AddSaveCache("diamondpresettlementtokenscore", m_nDiamondPreSettlementTokenScore);
        AddSaveCache("diamondsettlementtokenscore", m_nDiamondSettlementTokenScore);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 是否在获活动开启时间
    /// </summary>
    /// <returns></returns>
    public bool IsOpenTime()
    {
        long currTime = UtilityMethod.GetUnixTimeMilliseconds();
        if ((Param_Table.MiningOpenTime > 0 && currTime < Param_Table.MiningOpenTime) || (Param_Table.MiningCloseTime > 0 && currTime > Param_Table.MiningCloseTime))
        {
            return false;
        }
        return true;
    }

    /// <summary>
    /// 改变赛车质押操作
    /// </summary>
    public void ChangeCarPledge()
    {
        if (!IsOpenTime())
        {
            return;
        }
        Mining_Data mining_Data = ConfigManager.Mining.Get(MiningType.Car);
        long currTime = UtilityMethod.GetUnixTimeMilliseconds();
        int intervalTime = (int)(currTime - m_pCarMiningData.time);
        if (m_pCarMiningData.time != 0 && intervalTime < mining_Data.Cooldown * 60000)
        {
            return;
        }

        int mainCarLevel = this.GetSystem<CarCultivateSystem>().GetMainCarLevel();
        if (mainCarLevel < mining_Data.Condition)
        {
            return;
        }

        if (mainCarLevel == m_pCarMiningData.value)
        {
            return;
        }

        if (m_nCarLastPreSettlementTime == 0)
        {
            m_nCarLastPreSettlementTime = currTime;
            m_pCarMiningData.value = mainCarLevel;
            m_pCarMiningData.time = currTime;
        }
        else if ((currTime - m_pCarMiningData.time) <= 60000)
        {
            m_pCarMiningData.value = mainCarLevel;
        }
        else
        {
            bool isAdd = true;
            if (m_tCarMiningDatas.Count > 0)
            {
                MiningData miningData0 = m_tCarMiningDatas.Last();
                if ((currTime - miningData0.time) < 60000)
                {
                    miningData0.value = m_pCarMiningData.value;
                    miningData0.time = currTime;
                    isAdd = false;
                }
            }
            if (isAdd)
            {
                MiningData miningData1 = new MiningData();
                miningData1.value = m_pCarMiningData.value;
                miningData1.time = currTime;
                m_tCarMiningDatas.AddLast(miningData1);
            }
            m_pCarMiningData.value = mainCarLevel;
            m_pCarMiningData.time = currTime;
        }
        OnChangeData();

        Debug.Instance.Log($"MiningSystem ChangeCarPledge -> RoleId({this.GetPlayer().GetRoleId()}) Value({m_pCarMiningData.value} Time({m_pCarMiningData.time})", LogType.system);

        CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(m_pCarMiningData.value);
        if (carUpgrade_Data != null)
        {
            MiningManager.Instance.PlayerChangeCarMiningValue(this.GetPlayer().GetRoleId(), 0);//carUpgrade_Data.MiningValue
        }

        this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent207, 1);
    }

    /// <summary>
    /// 添加钻石挖矿质押
    /// </summary>
    public void AddDiamondPledge(int i_nAddDiamondPledge)
    {
        if (!IsOpenTime())
        {
            return;
        }
        Mining_Data mining_Data = ConfigManager.Mining.Get(MiningType.Diamond);
        long currTime = UtilityMethod.GetUnixTimeMilliseconds();
        int intervalTime = (int)(currTime - m_pDiamondMiningData.time);
        if (m_pDiamondMiningData.time != 0 && intervalTime < mining_Data.Cooldown * 60000)
        {
            return;
        }

        if (i_nAddDiamondPledge < mining_Data.Condition)
        {
            return;
        }

        if (!this.GetSystem<BaseInfoSystem>().CostDiamond(i_nAddDiamondPledge))
        {
            return;
        }

        if (m_nDiamondLastPreSettlementTime == 0)
        {
            m_nDiamondLastPreSettlementTime = currTime;
            m_pDiamondMiningData.value += i_nAddDiamondPledge;
            m_pDiamondMiningData.time = currTime;
        }
        else if ((currTime - m_pDiamondMiningData.time) <= 60000)
        {
            m_pDiamondMiningData.value += i_nAddDiamondPledge;
        }
        else
        {
            bool isAdd = true;
            if (m_tDiamondMiningDatas.Count > 0)
            {
                MiningData miningData0 = m_tDiamondMiningDatas.Last();
                if ((currTime - miningData0.time) < 60000)
                {
                    miningData0.value = m_pDiamondMiningData.value;
                    miningData0.time = currTime;
                    isAdd = false;
                }
            }
            if (isAdd)
            {
                MiningData miningData1 = new MiningData();
                miningData1.value = m_pDiamondMiningData.value;
                miningData1.time = currTime;
                m_tDiamondMiningDatas.AddLast(miningData1);
            }
            m_pDiamondMiningData.value += i_nAddDiamondPledge;
            m_pDiamondMiningData.time = currTime;
        }
        OnChangeData();

        Debug.Instance.Log($"MiningSystem AddDiamondPledge -> RoleId({this.GetPlayer().GetRoleId()}) Value({m_pDiamondMiningData.value} Time({m_pDiamondMiningData.time})", LogType.system);

        MiningManager.Instance.PlayerChangeDiamondMiningValue(this.GetPlayer().GetRoleId(), m_pDiamondMiningData.value);

        this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent202, 1);
    }

    /// <summary>
    /// 取消赛车挖矿质押
    /// </summary>
    public void CancelCarPledge()
    {
        if (!IsOpenTime())
        {
            return;
        }
        m_pCarMiningData.value = 0;
        m_pCarMiningData.time = 0;

        m_tCarMiningDatas.Clear();
        m_nCarLastPreSettlementTime = 0;

        OnChangeData();

        Debug.Instance.Log($"MiningSystem CancelCarPledge -> RoleId({this.GetPlayer().GetRoleId()})", LogType.system);

        MiningManager.Instance.PlayerChangeCarMiningValue(this.GetPlayer().GetRoleId(), m_pCarMiningData.value);
    }

    /// <summary>
    /// 取消钻石挖矿质押
    /// </summary>
    public void CancelDiamondPledge()
    {
        if (!IsOpenTime())
        {
            return;
        }
        this.GetSystem<BaseInfoSystem>().AddDiamond(m_pDiamondMiningData.value);

        m_pDiamondMiningData.value = 0;
        m_pDiamondMiningData.time = 0;

        m_tDiamondMiningDatas.Clear();
        m_nDiamondLastPreSettlementTime = 0;

        OnChangeData();

        Debug.Instance.Log($"MiningSystem CancelDiamondPledge -> RoleId({this.GetPlayer().GetRoleId()})", LogType.system);

        MiningManager.Instance.PlayerChangeDiamondMiningValue(this.GetPlayer().GetRoleId(), m_pDiamondMiningData.value);
    }

    /// <summary>
    /// 赛车预结算Token积分
    /// </summary>
    public void CarPreSettlementTokenScore(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        if (!IsOpenTime())
        {
            return;
        }
        if (m_nCarLastPreSettlementTime != 0)
        {
            Mining_Data mining_Data = ConfigManager.Mining.Get(MiningType.Car);
            long scoreCoefficient = mining_Data.ScoreCoefficient;
            long carLastPreSettlementIntervalTime = (i_nCurrTime - m_nCarLastPreSettlementTime) / 60000;
            long preSettlementTime = mining_Data.PreSettlementTime;
            int count = (int)(carLastPreSettlementIntervalTime / preSettlementTime);
            if (count > 0)
            {
                MiningData miningData0 = new MiningData();
                miningData0.value = m_pCarMiningData.value;
                miningData0.time = i_nCurrTime;
                m_tCarMiningDatas.AddLast(miningData0);

                long score = 0;
                long lastPreSettlementTime = m_nCarLastPreSettlementTime + preSettlementTime * count * 60000;
                long startTime = m_nCarLastPreSettlementTime;
                while (m_tCarMiningDatas.Count > 0)
                {
                    MiningData miningData1 = m_tCarMiningDatas.First();
                    CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(miningData1.value);
                    long carMiningValue = 0;//carUpgrade_Data.MiningValue
                    if (miningData1.time <= lastPreSettlementTime)
                    {
                        long intervalTime = (miningData1.time - startTime) / 60000;
                        score += carMiningValue * intervalTime * scoreCoefficient;
                        startTime = miningData1.time;
                        m_tCarMiningDatas.RemoveFirst();
                    }
                    else
                    {
                        long intervalTime = (lastPreSettlementTime - startTime) / 60000;
                        score += carMiningValue * intervalTime * scoreCoefficient;
                        startTime = miningData1.time;
                        break;
                    }
                }

                m_nCarPreSettlementTokenScore += score;
                m_nCarLastPreSettlementTime = m_nCarLastPreSettlementTime + preSettlementTime * count * 60000;
                OnChangeData();

                Debug.Instance.Log($"MiningSystem CarPreSettlementTokenScore -> RoleId({this.GetPlayer().GetRoleId()}) Score({score})", LogType.system);

                ReceiveCarTokenScore();
            }
        }
    }

    /// <summary>
    /// 钻石预结算Token积分
    /// </summary>
    public void DiamondPreSettlementTokenScore(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        if (!IsOpenTime())
        {
            return;
        }
        if (m_nDiamondLastPreSettlementTime != 0)
        {
            Mining_Data mining_Data = ConfigManager.Mining.Get(MiningType.Diamond);
            long scoreCoefficient = mining_Data.ScoreCoefficient;
            long lastPreSettlementIntervalTime = (i_nCurrTime - m_nDiamondLastPreSettlementTime) / 60000;
            long preSettlementTime = mining_Data.PreSettlementTime;
            int count = (int)(lastPreSettlementIntervalTime / preSettlementTime);
            if (count > 0)
            {
                MiningData miningData0 = new MiningData();
                miningData0.value = m_pDiamondMiningData.value;
                miningData0.time = i_nCurrTime;
                m_tDiamondMiningDatas.AddLast(miningData0);

                long score = 0;
                long lastPreSettlementTime = m_nDiamondLastPreSettlementTime + preSettlementTime * count * 60000;
                long startTime = m_nDiamondLastPreSettlementTime;
                while (m_tDiamondMiningDatas.Count > 0)
                {
                    MiningData miningData1 = m_tDiamondMiningDatas.First();
                    if (miningData1.time <= lastPreSettlementTime)
                    {
                        long intervalTime = (miningData1.time - startTime) / 60000;
                        score += miningData1.value * intervalTime * scoreCoefficient;
                        startTime = miningData1.time;
                        m_tDiamondMiningDatas.RemoveFirst();
                    }
                    else
                    {
                        long intervalTime = (lastPreSettlementTime - startTime) / 60000;
                        score += miningData1.value * intervalTime * scoreCoefficient;
                        startTime = miningData1.time;
                        break;
                    }
                }

                m_nDiamondPreSettlementTokenScore += score;
                m_nDiamondLastPreSettlementTime = m_nDiamondLastPreSettlementTime + preSettlementTime * count * 60000;
                OnChangeData();

                Debug.Instance.Log($"MiningSystem DiamondPreSettlementTokenScore -> RoleId({this.GetPlayer().GetRoleId()}) Score({score})", LogType.system);

                ReceiveDiamondTokenScore();
            }
        }
    }

    /// <summary>
    /// 领取赛车Token积分
    /// </summary>
    public void ReceiveCarTokenScore()
    {
        if (!IsOpenTime())
        {
            return;
        }
        if (m_nCarPreSettlementTokenScore < 1)
        {
            return;
        }

        MiningManager.Instance.ReceiveCarTokenScore(this.GetPlayer().GetRoleId(), m_nCarPreSettlementTokenScore / ScoreCoefficientValue, (ResMsgBodyReceiveCarTokenScorePoolValue resMsgBodyReceiveCarTokenScorePoolValue) =>
        {
            if (resMsgBodyReceiveCarTokenScorePoolValue.Value > 0)
            {
                this.GetSystem<BaseInfoSystem>().AddTokenScore(resMsgBodyReceiveCarTokenScorePoolValue.Value);
                m_nCarSettlementTokenScore += resMsgBodyReceiveCarTokenScorePoolValue.Value;
                m_nCarPreSettlementTokenScore = m_nCarPreSettlementTokenScore - resMsgBodyReceiveCarTokenScorePoolValue.Value * ScoreCoefficientValue;
                OnChangeData();

                this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent120, 1);

                Debug.Instance.Log($"MiningSystem ReceiveCarTokenScore -> RoleId({this.GetPlayer().GetRoleId()}) ReceiveScore({resMsgBodyReceiveCarTokenScorePoolValue.Value})", LogType.system);
            }
        });
    }

    /// <summary>
    /// 领取钻石Token积分
    /// </summary>
    public void ReceiveDiamondTokenScore()
    {
        if (!IsOpenTime())
        {
            return;
        }
        if (m_nDiamondPreSettlementTokenScore < 1)
        {
            return;
        }

        MiningManager.Instance.ReceiveDiamondTokenScore(this.GetPlayer().GetRoleId(), m_nDiamondPreSettlementTokenScore / ScoreCoefficientValue, (ResMsgBodyReceiveDiamondTokenScorePoolValue resMsgBodyReceiveDiamondTokenScorePoolValue) =>
        {
            if (resMsgBodyReceiveDiamondTokenScorePoolValue.Value > 0)
            {
                this.GetSystem<BaseInfoSystem>().AddTokenScore(resMsgBodyReceiveDiamondTokenScorePoolValue.Value);
                m_nDiamondSettlementTokenScore += resMsgBodyReceiveDiamondTokenScorePoolValue.Value;
                m_nDiamondPreSettlementTokenScore = m_nDiamondPreSettlementTokenScore - resMsgBodyReceiveDiamondTokenScorePoolValue.Value * ScoreCoefficientValue;
                OnChangeData();

                this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent120, 1);

                Debug.Instance.Log($"MiningSystem ReceiveDiamondTokenScore -> RoleId({this.GetPlayer().GetRoleId()}) ReceiveScore({resMsgBodyReceiveDiamondTokenScorePoolValue.Value})", LogType.system);
            }
        });
    }
}

/// <summary>
/// 挖矿质押数据
/// </summary>
public class MiningData
{
    /// <summary>
    /// 质押值
    /// </summary>
    public int value;
    /// <summary>
    /// 质押时间
    /// </summary>
    public long time;
}