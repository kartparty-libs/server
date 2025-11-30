using Google.Protobuf;
using Proto;
using System.Data;
using static CarCultivateSystem;

/// <summary>
/// 赛车养成系统
/// </summary>
public class CarCultivateSystem : BasePlayerSystem
{
    /// <summary>
    /// 赛车养成列表
    /// </summary>
    protected Dictionary<CarModuleTypeEnum, CarCultivateData> m_pCarCultivateDatas = new Dictionary<CarModuleTypeEnum, CarCultivateData>();

    /// <summary>
    /// 上次结算时间戳
    /// </summary>
    protected long m_nLastSettlementTime;

    /// <summary>
    /// 可领取免费加速时长时间戳
    /// </summary>
    protected long m_nLastFreeGetSpeedUpTime;

    /// <summary>
    /// 加速结束时间戳
    /// </summary>
    protected long m_nSpeedUpEndTime;

    /// <summary>
    /// 是否自动升级
    /// </summary>
    protected bool m_bIsAutoUpgradeCar = false;

    /// <summary>
    /// 距离上次请求间隔金币收益
    /// </summary>
    protected long m_nIntervalEarningsGold;

    /// <summary>
    /// 离线时间
    /// </summary>
    protected long m_nIntervalTime;

    public CarCultivateSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
        InitCarCultivateData();
    }

    public override string GetSqlTableName() => SqlTableName.role_carcultivateinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_nLastSettlementTime = Convert.ToInt64(dataRow["lastsettlementtime"]);
            m_nLastFreeGetSpeedUpTime = Convert.ToInt64(dataRow["lastfreegetspeeduptime"]);
            m_nSpeedUpEndTime = Convert.ToInt64(dataRow["speedupendtime"]);
            m_bIsAutoUpgradeCar = Convert.ToInt16(dataRow["isautoupgradecar"]) == 1;
            string carcultivateInfo = Convert.ToString(dataRow["carcultivateinfo"]);
            if (carcultivateInfo != null)
            {
                Dictionary<CarModuleTypeEnum, CarCultivateData> carcultivateInfos = UtilityMethod.JsonDeserializeObject<Dictionary<CarModuleTypeEnum, CarCultivateData>>(carcultivateInfo);
                if (carcultivateInfos != null)
                {
                    m_pCarCultivateDatas = new Dictionary<CarModuleTypeEnum, CarCultivateData>(carcultivateInfos);
                }
            }
        }

        if (m_nLastSettlementTime == 0)
        {
            m_nLastSettlementTime = UtilityMethod.GetUnixTimeMilliseconds();
        }
    }

    public override void OnHandle(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        base.OnHandle(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);
        //m_nIntervalEarningsGold = 0;
        //foreach (var item in m_pCarCultivateDatas)
        //{
        //    item.Value.intervalLevelUp = 0;
        //}
        //long residueTime = Math.Min(i_nCurrTime - m_nLastSettlementTime, Param_Table.OfflineEarningsTime);
        //m_nIntervalTime = residueTime;
        //if (m_bIsAutoUpgradeCar)
        //{
        //    Debug.Instance.Log($"CarCultivateSystem AutoUpgradeCar Start -> roleId =  {this.m_pPlayer.GetRoleId()} CurrGold = {this.GetSystem<BaseInfoSystem>().GetGold()}  residueTime = {residueTime}");
        //    residueTime = AutoUpgradeCar(i_nCurrTime, i_nLastHandleTime, residueTime);
        //    Debug.Instance.Log($"CarCultivateSystem AutoUpgradeCar End -> roleId =  {this.m_pPlayer.GetRoleId()} CurrGold = {this.GetSystem<BaseInfoSystem>().GetGold()}  residueTime = {residueTime}");
        //}
        //SettlementEarnings(i_nCurrTime, i_nLastHandleTime, residueTime);
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyCarCultivateSystem resMsgBodyCarCultivateSystem = new ResMsgBodyCarCultivateSystem();
        resMsgBodyCarCultivateSystem.LastFreeGetSpeedUpTime = m_nLastFreeGetSpeedUpTime;
        resMsgBodyCarCultivateSystem.SpeedUpEndTime = m_nSpeedUpEndTime;
        resMsgBodyCarCultivateSystem.IsAutoUpgradeCar = m_bIsAutoUpgradeCar;
        resMsgBodyCarCultivateSystem.IntervalEarningsGold = m_nIntervalEarningsGold;
        resMsgBodyCarCultivateSystem.IntervalTime = m_nIntervalTime;
        foreach (var item in m_pCarCultivateDatas)
        {
            ResCarCultivateData resCarCultivateData = new ResCarCultivateData();
            resCarCultivateData.CarModuleTypeEnum = item.Value.carModuleTypeEnum;
            resCarCultivateData.Level = item.Value.level;
            resCarCultivateData.IntervalLevelUp = item.Value.intervalLevelUp;
            resMsgBodyCarCultivateSystem.CarCultivateDatas.Add(resCarCultivateData);
        }
        return resMsgBodyCarCultivateSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();
        AddSaveCache("lastsettlementtime", m_nLastSettlementTime);
        AddSaveCache("lastfreegetspeeduptime", m_nLastFreeGetSpeedUpTime);
        AddSaveCache("speedupendtime", m_nSpeedUpEndTime);
        AddSaveCache("isautoupgradecar", m_bIsAutoUpgradeCar ? 1 : 0);
        AddSaveCache("carcultivateinfo", UtilityMethod.JsonSerializeObject(m_pCarCultivateDatas));
    }

    public override void OnNewSeason(int i_nSeasonId)
    {
        base.OnNewSeason(i_nSeasonId);

        InitCarCultivateData();

        OnChangeData();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    public void InitCarCultivateData()
    {
        m_pCarCultivateDatas.Clear();
        for (int i = 1; i < (int)CarModuleTypeEnum.Count; i++)
        {
            CarCultivateData carCultivateData = new CarCultivateData();
            carCultivateData.carModuleTypeEnum = (CarModuleTypeEnum)i;
            carCultivateData.level = 1;
            carCultivateData.intervalLevelUp = 0;
            m_pCarCultivateDatas.Add((CarModuleTypeEnum)i, carCultivateData);
        }
    }

    /// <summary>
    /// 获取赛车养成数据
    /// </summary>
    /// <param name="i_eCarModuleTypeEnum"></param>
    /// <returns></returns>
    public CarCultivateData GetCarCultivateData(CarModuleTypeEnum i_eCarModuleTypeEnum)
    {
        m_pCarCultivateDatas.TryGetValue(i_eCarModuleTypeEnum, out CarCultivateData carCultivateData);
        return carCultivateData;
    }

    /// <summary>
    /// 获取赛车本体等级
    /// </summary>
    /// <returns></returns>
    public int GetMainCarLevel()
    {
        if (m_pCarCultivateDatas.TryGetValue(CarModuleTypeEnum.Car, out CarCultivateData carCultivateData))
        {
            return carCultivateData.level;
        }
        return 0;
    }

    /// <summary>
    /// 是否可以升级赛车本体
    /// </summary>
    /// <returns></returns>
    //public bool IsUpgradeMainCar()
    //{
    //    return false;
    //    CarCultivateData mainCarCultivateData = GetCarCultivateData(CarModuleTypeEnum.Car);
    //    if (mainCarCultivateData.level >= ConfigManager.CarUpgrade.GetItem(ConfigManager.CarUpgrade.Count - 1).Id)
    //    {
    //        return false;
    //    }
    //    foreach (var item in m_pCarCultivateDatas)
    //    {
    //        CarCultivateData carCultivateData = GetCarCultivateData(item.Value.carModuleTypeEnum);
    //        if (item.Value.carModuleTypeEnum != CarModuleTypeEnum.Car)
    //        {
    //            if (carCultivateData.level <= mainCarCultivateData.level)
    //            {
    //                return false;
    //            }
    //        }
    //    }
    //    return true;
    //}

    /// <summary>
    /// 是否可以升级赛车部件
    /// </summary>
    /// <param name="i_pCarCultivateData"></param>
    /// <returns></returns>
    public bool IsUpgradeCarModule(CarCultivateData i_pCarCultivateData)
    {
        if (i_pCarCultivateData.carModuleTypeEnum == CarModuleTypeEnum.Car)
        {
            return false;
        }
        if (ConfigManager.CarUpgrade.Get(i_pCarCultivateData.level + 1) == null)
        {
            return false;
        }
        CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(i_pCarCultivateData.level);
        long costGold = carUpgrade_Data.Costs[(int)i_pCarCultivateData.carModuleTypeEnum];
        int[] costItem = carUpgrade_Data.CostItems[(int)i_pCarCultivateData.carModuleTypeEnum];
        if (this.GetSystem<BaseInfoSystem>().IsCostGold(costGold) && this.GetSystem<ItemSystem>().IsCostItem(costItem[0], costItem[1]))
        {
            return true;
        }
        return false;
    }

    /// <summary>
    /// 自动升级
    /// </summary>
    /// <param name="i_nCurrTime"></param>
    /// <param name="i_nLastHandleTime"></param>
    /// <param name="i_nResidueTime"></param>
    private long AutoUpgradeCar(long i_nCurrTime, long i_nLastHandleTime, long i_nResidueTime)
    {
        // 最终操作的养成对象，默认是车本体
        CarCultivateData carCultivateData0 = GetCarCultivateData(CarModuleTypeEnum.Car);
        // 车本体养成对象表
        CarUpgrade_Data carUpgrade_Data0 = ConfigManager.CarUpgrade.Get(carCultivateData0.level);

        // 检测是否升车本体
        //if (!IsUpgradeMainCar())
        //{
        //    CarCultivateData carCultivateData1 = GetCarCultivateData(CarModuleTypeEnum.Module1);
        //    foreach (var item in m_pCarCultivateDatas)
        //    {
        //        CarCultivateData carCultivateData2 = GetCarCultivateData(item.Value.carModuleTypeEnum);
        //        if (item.Value.carModuleTypeEnum != CarModuleTypeEnum.Car)
        //        {
        //            if (carCultivateData1.level > carCultivateData2.level)
        //            {
        //                carCultivateData1 = carCultivateData2;
        //            }
        //        }
        //    }

        //    if (IsUpgradeCarModule(carCultivateData1))
        //    {
        //        // 将最终操作的养成对象 设置为最低等级的部件对象
        //        carCultivateData0 = carCultivateData1;
        //    }
        //    else
        //    {
        //        carCultivateData0 = null;
        //    }
        //}

        if (carCultivateData0 != null)
        {
            // 最低等级的部件对象表
            CarUpgrade_Data carUpgrade_Data1 = ConfigManager.CarUpgrade.Get(carCultivateData0.level);

            BaseInfoSystem baseInfoSystem = this.GetSystem<BaseInfoSystem>();

            long costGold = carUpgrade_Data1.Costs[(int)carCultivateData0.carModuleTypeEnum];
            if (baseInfoSystem.CostGold(costGold))
            {
                carCultivateData0.level++;
                carCultivateData0.intervalLevelUp++;
                Debug.Instance.Log($"CarCultivateSystem AutoUpgradeCar -> RoleId({this.GetPlayer().GetRoleId()}) CarModuleTypeEnum({carCultivateData0.carModuleTypeEnum}) Level({carCultivateData0.level}) , CostGold({costGold})", LogType.system);

                if (carCultivateData0.carModuleTypeEnum == CarModuleTypeEnum.Car)
                {
                    this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent115, 1);
                    this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent206, carCultivateData0.level);
                }

                return AutoUpgradeCar(i_nCurrTime, i_nLastHandleTime, i_nResidueTime);
            }

            long currGold = baseInfoSystem.GetGold();
            long shortGold = costGold - currGold;
            long needTime = shortGold / 1 * 1000;//GetProductSeconds()

            BuyEarningsSpeedUp(0, m_nLastSettlementTime);
            long speedTime = Math.Min((m_nSpeedUpEndTime - m_nLastSettlementTime), needTime);
            if (speedTime > 0)
            {
                needTime = needTime - speedTime + speedTime / ConfigManager.Param.Get("EarningsSpeedMultiplier").IntParam;
            }
            if (needTime < i_nResidueTime)
            {
                m_nLastSettlementTime = m_nLastSettlementTime + needTime;
                carCultivateData0.level++;
                carCultivateData0.intervalLevelUp++;
                baseInfoSystem.CostGold(currGold);
                this.GetSystem<BaseInfoSystem>().AddCultivateGold(shortGold);
                m_nIntervalEarningsGold += shortGold;

                Debug.Instance.Log($"CarCultivateSystem AutoUpgradeCar -> RoleId({this.GetPlayer().GetRoleId()}) CarModuleTypeEnum({carCultivateData0.carModuleTypeEnum}) Level({carCultivateData0.level}) , CostGold({costGold})", LogType.system);

                if (carCultivateData0.carModuleTypeEnum == CarModuleTypeEnum.Car)
                {
                    this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent115, 1);
                    this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent206, carCultivateData0.level);
                }

                return AutoUpgradeCar(i_nCurrTime, i_nLastHandleTime, i_nResidueTime - needTime);
            }
        }
        BuyEarningsSpeedUp(0, m_nLastSettlementTime);

        return i_nResidueTime;
    }

    /// <summary>
    /// 获取当前每秒收益
    /// </summary>
    /// <returns></returns>
    //public int GetProductSeconds()
    //{
    //    int productSeconds = 0;
    //    foreach (var item in m_pCarCultivateDatas)
    //    {
    //        CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(item.Value.level);
    //        if (carUpgrade_Data != null)
    //        {
    //            productSeconds += carUpgrade_Data.CarProductSeconds[(int)item.Key];
    //        }
    //    }
    //    return productSeconds;
    //}


    /// <summary>
    /// 获取评分
    /// </summary>
    /// <returns></returns>
    public int GetScoring()
    {
        int scoring = 0;
        foreach (var item in m_pCarCultivateDatas)
        {
            CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(item.Value.level);
            if (carUpgrade_Data != null)
            {
                scoring += carUpgrade_Data.Scorings[(int)item.Key];
            }
        }
        return scoring;
    }

    /// <summary>
    /// 结算收益
    /// </summary>
    /// <param name="i_nCurrTime"></param>
    /// <param name="i_nLastHandleTime"></param>
    /// <param name="i_nResidueTime"></param>
    private void SettlementEarnings(long i_nCurrTime, long i_nLastHandleTime, long i_nResidueTime)
    {
        CarCultivateData carCultivateData = GetCarCultivateData(CarModuleTypeEnum.Car);
        if (carCultivateData == null)
        {
            return;
        }
        Debug.Instance.Log($"CarCultivateSystem SettlementEarnings Start -> roleId =  {this.m_pPlayer.GetRoleId()} residueTime = {i_nResidueTime}");
        CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(carCultivateData.level);
        if (carUpgrade_Data == null)
        {
            return;
        }
        Debug.Instance.Log($"CarCultivateSystem SettlementEarnings Start -> roleId =  {this.m_pPlayer.GetRoleId()} residueTime = {i_nResidueTime}");
        long time = i_nResidueTime / 1000;
        if (time >= 1)
        {
            long speedTime = Math.Min((m_nSpeedUpEndTime - m_nLastSettlementTime) / 1000, time);
            if (speedTime < 0) speedTime = 0;

            m_nLastSettlementTime = i_nCurrTime - (i_nResidueTime - time * 1000); // 保证毫秒位不丢失

            time = time + (ConfigManager.Param.Get("EarningsSpeedMultiplier").IntParam - 1) * speedTime;
            long goldEarnings = 1 * time;//GetProductSeconds()
            if (goldEarnings > 0)
            {
                this.GetSystem<BaseInfoSystem>().AddGold(goldEarnings);
                this.GetSystem<BaseInfoSystem>().AddCultivateGold(goldEarnings);
                m_nIntervalEarningsGold += goldEarnings;
            }
            OnChangeData();

            Debug.Instance.Log($"CarCultivateSystem SettlementEarnings -> RoleId({this.GetPlayer().GetRoleId()}) GoldEarnings({goldEarnings})", LogType.system);
            Debug.Instance.Log($"CarCultivateSystem SettlementEarnings End -> roleId = {this.m_pPlayer.GetRoleId()}  goldEarnings = {goldEarnings}  time = {time}  lastSettlementTime = {m_nLastSettlementTime}");
        }
    }

    /// <summary>
    /// 升级赛车养成部件
    /// </summary>
    /// <param name="i_eCarModuleTypeEnum"></param>
    public bool UpgradeCarCultivate(CarModuleTypeEnum i_eCarModuleTypeEnum)
    {
        if (m_pCarCultivateDatas.TryGetValue(i_eCarModuleTypeEnum, out CarCultivateData carCultivateData))
        {
            CarUpgrade_Data carUpgrade_Data = ConfigManager.CarUpgrade.Get(carCultivateData.level);
            if (carUpgrade_Data != null)
            {
                if (IsUpgradeCarModule(carCultivateData))
                {
                    long costGold = carUpgrade_Data.Costs[(int)carCultivateData.carModuleTypeEnum];
                    int[] costItem = carUpgrade_Data.CostItems[(int)carCultivateData.carModuleTypeEnum];
                    this.GetSystem<BaseInfoSystem>().CostGold(costGold);
                    this.GetSystem<ItemSystem>().CostItem(costItem[0], costItem[1]);

                    carCultivateData.level++;

                    this.GetSystem<TaskSystem>().TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent124, GetScoring());
                    this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent125, 1);

                    OnChangeData();
                    Debug.Instance.Log($"CarCultivateSystem UpgradeCarCultivate -> RoleId({this.GetPlayer().GetRoleId()}) CarModuleTypeEnum({i_eCarModuleTypeEnum.ToString()}) Level({carCultivateData.level})", LogType.system);
                    return true;
                }
            }
        }
        return false;
    }

    /// <summary>
    /// 升级赛车养成部件 一键升级
    /// </summary>
    public void UpgradeCarCultivates()
    {
        bool bIsUpgrade = false;
        foreach (var item in m_pCarCultivateDatas)
        {
            if (UpgradeCarCultivate(item.Value.carModuleTypeEnum))
            {
                if (!bIsUpgrade)
                {
                    bIsUpgrade = true;
                }
            }
        }
        if (bIsUpgrade)
        {
            UpgradeCarCultivates();
        }
        return;
    }

    /// <summary>
    /// 购买收益加速
    /// </summary>
    /// <param name="i_nType"></param>
    /// <param name="i_nCurrTime"></param>
    public bool BuyEarningsSpeedUp(int i_nType, long i_nCurrTime)
    {
        if (i_nType < 0 || i_nType > 2)
        {
            return false;
        }
        int[] earningsSpeedUpTime = ConfigManager.Param.Get("EarningsSpeedUpTime").IntParams;
        int[] earningsSpeedUpDiamond = ConfigManager.Param.Get("EarningsSpeedUpDiamond").IntParams;
        int getFreeSpeedUpIntervalTime = ConfigManager.Param.Get("GetFreeSpeedUpIntervalTime").IntParam * 60000;
        if (i_nType == 0)
        {
            int interval = (int)(i_nCurrTime - m_nLastFreeGetSpeedUpTime);
            if (m_nLastFreeGetSpeedUpTime != 0 && interval < 0)
            {
                return false;
            }
            m_nLastFreeGetSpeedUpTime = i_nCurrTime + getFreeSpeedUpIntervalTime;
        }
        else
        {
            if (!this.GetSystem<BaseInfoSystem>().CostDiamond(earningsSpeedUpDiamond[i_nType]))
            {
                return false;
            }
        }
        if (m_nSpeedUpEndTime < i_nCurrTime)
        {
            m_nSpeedUpEndTime = i_nCurrTime;
        }
        m_nSpeedUpEndTime += earningsSpeedUpTime[i_nType] * 60000;

        OnChangeData();
        Debug.Instance.Log($"CarCultivateSystem BuyEarningsSpeedUp -> RoleId({this.GetPlayer().GetRoleId()}) Type({i_nType})", LogType.system);
        return true;
    }

    /// <summary>
    /// 购买自动升级功能
    /// </summary>
    public bool BuyAutoUpgradeCar()
    {
        //if (m_bIsAutoUpgradeCar)
        //{
        //    return false;
        //}

        //if (this.GetSystem<BaseInfoSystem>().CostDiamond(ConfigManager.Param.Get("BuyAutoUpgradeCost").IntParam))
        //{
        //    m_bIsAutoUpgradeCar = true;
        //    OnChangeData();
        //    Debug.Instance.Log($"CarCultivateSystem BuyAutoUpgradeCar -> RoleId({this.GetPlayer().GetRoleId()})", LogType.system);
        //    return true;
        //}
        return false;
    }
}
/// <summary>
/// 赛车养成数据
/// </summary>
public class CarCultivateData()
{
    /// <summary>
    /// 养成类型
    /// </summary>
    public CarModuleTypeEnum carModuleTypeEnum;
    /// <summary>
    /// 等级
    /// </summary>
    public int level;
    /// <summary>
    /// 距离上次请求间隔赛车养成升级数
    /// </summary>
    public int intervalLevelUp;
}