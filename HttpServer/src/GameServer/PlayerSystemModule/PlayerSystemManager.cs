using Google.Protobuf;

/// <summary>
/// 玩家系统管理器
/// </summary>
public class PlayerSystemManager
{
    /// <summary>
    /// 玩家
    /// </summary>
    private Player m_pPlayer;

    /// <summary>
    /// 系统列表
    /// </summary>
    private Dictionary<Type, BasePlayerSystem> m_tPlayerSystems = new Dictionary<Type, BasePlayerSystem>();

    /// <summary>
    /// 系统刷新列表
    /// </summary>
    private Dictionary<Type, BasePlayerSystem> m_tPlayerSystemUpdates = new Dictionary<Type, BasePlayerSystem>();

    public PlayerSystemManager(Player i_pPlayer)
    {
        m_pPlayer = i_pPlayer;

        // 注册玩家系统
        m_tPlayerSystems.Add(typeof(BaseInfoSystem), new BaseInfoSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(TaskSystem), new TaskSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(CarCultivateSystem), new CarCultivateSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(LuckyBoxSystem), new LuckyBoxSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(ShopSystem), new ShopSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(MapSystem), new MapSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(GiftCodeSystem), new GiftCodeSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(InviteSystem), new InviteSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(EnergySystem), new EnergySystem(i_pPlayer, this)); 
        m_tPlayerSystems.Add(typeof(ExtendSystem), new ExtendSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(GiftSystem), new GiftSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(LuckyTurntableSystem), new LuckyTurntableSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(ItemSystem), new ItemSystem(i_pPlayer, this));
        m_tPlayerSystems.Add(typeof(SeasonSystem), new SeasonSystem(i_pPlayer, this));
        //m_tPlayerSystems.Add(typeof(MiningSystem), new MiningSystem(i_pPlayer, this));
        //m_tPlayerSystems.Add(typeof(TreasureChestSystem), new TreasureChestSystem(i_pPlayer, this));

        // 注册玩家系统Update
        m_tPlayerSystemUpdates.Add(typeof(InviteSystem), m_tPlayerSystems[typeof(InviteSystem)]);
    }

    public void Initializer(bool i_bIsNewPlayer)
    {
        // 初始化玩家系统
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.Initializer(i_bIsNewPlayer);
        }
    }

    public void DayRefresh()
    {
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.DayRefresh();
        }
    }

    public void SaveData()
    {
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.SaveData();
        }
    }

    public void Update(int i_nMillisecondDelay)
    {
        foreach (var item in m_tPlayerSystemUpdates)
        {
            item.Value.Update(i_nMillisecondDelay);
        }
    }

    public void Delete()
    {
        // 删除玩家系统
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.Delete();
        }
    }
    public void OnHandle(long i_nCurrTime, long i_nLastHandleTime, long i_nIntervalTime)
    {
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.OnHandle(i_nCurrTime, i_nLastHandleTime, i_nIntervalTime);
        }
    }
    public void OnNewSeason(int i_nSeasonId)
    {
        foreach (var item in m_tPlayerSystems)
        {
            item.Value.OnNewSeason(i_nSeasonId);
        }
    }
    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取指定系统
    /// </summary>
    /// <typeparam name="T0"></typeparam>
    /// <returns></returns>
    public T0 GetSystem<T0>() where T0 : BasePlayerSystem
    {
        if (m_tPlayerSystems.TryGetValue(typeof(T0), out BasePlayerSystem? __playerSystem))
        {
            return __playerSystem as T0;
        }
        return null;
    }

    /// <summary>
    /// 获取指定系统
    /// </summary>
    /// <typeparam name="T0"></typeparam>
    /// <returns></returns>
    public BasePlayerSystem GetSystem(Type type)
    {
        if (m_tPlayerSystems.TryGetValue(type, out BasePlayerSystem? __playerSystem))
        {
            return __playerSystem;
        }
        return null;
    }

    /// <summary>
    /// 获取所有系统消息体表
    /// </summary>
    /// <returns></returns>
    public List<IMessage> GetAllSystemMsgBodys()
    {
        List<IMessage> result = new List<IMessage>() { m_pPlayer.GetResMsgBody() };
        foreach (var item in m_tPlayerSystems)
        {
            IMessage message = item.Value.GetResMsgBody();
            if (message != null)
            {
                result.Add(message);
            }
        }
        return result;
    }

    /// <summary>
    /// 获取改变过数据的系统消息体表
    /// </summary>
    /// <returns></returns>
    public List<IMessage> GetChangeDataSystemMsgBodys()
    {
        List<IMessage> result = new List<IMessage>() { m_pPlayer.GetResMsgBody() };
        foreach (var item in m_tPlayerSystems)
        {
            if (item.Value.IsChangeData())
            {
                IMessage message = item.Value.GetResMsgBody();
                if (message != null)
                {
                    result.Add(message);
                }
            }
        }
        return result;
    }
}