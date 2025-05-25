using Google.Protobuf;
using Proto;
using System.Data;
using System.Diagnostics;

/// <summary>
/// 地图系统
/// </summary>
public class MapSystem : BasePlayerSystem
{
    /// <summary>
    /// 总比赛完成次数
    /// </summary>
    private int m_nTotalCompleteCount = 0;

    /// <summary>
    /// 今日比赛完成次数
    /// </summary>
    private int m_nTodayCompleteCount = 0;

    /// <summary>
    /// 是否已经消耗体力
    /// </summary>
    private bool m_bIsCost = false;

    /// <summary>
    /// 连胜次数
    /// </summary>
    private Dictionary<MapType, int> m_pWinningStreaks = new Dictionary<MapType, int>();

    /// <summary>
    /// 历史记录
    /// </summary>
    private List<MapHistoryData> m_pMapHistoryDatas = new List<MapHistoryData>();

    /// <summary>
    /// 总奖牌数量
    /// </summary>
    private List<int> m_tTotalMedalCounts = new List<int> { 0, 0, 0 };

    /// <summary>
    /// 周奖牌数量
    /// </summary>
    private List<int> m_tWeekMedalCounts = new List<int> { 0, 0, 0 };

    public MapSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
    }
    public override string GetSqlTableName() => SqlTableName.role_mapinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            m_nTotalCompleteCount = Convert.ToInt32(dataRow["totalcompletecount"]);
            m_nTodayCompleteCount = Convert.ToInt32(dataRow["todaycompletecount"]);
            var winningstreaks = UtilityMethod.JsonDeserializeObject<Dictionary<MapTypeServer, int>>(Convert.ToString(dataRow["winningstreaks"]));
            if (winningstreaks != null)
            {
                if (winningstreaks.Count > 0)
                {
                    foreach (var item in winningstreaks)
                    {
                        m_pWinningStreaks.Add((MapType)item.Key, item.Value);
                    }
                }
            }

            string maphistorydatas = Convert.ToString(dataRow["maphistorydatas"]);
            List<MapHistoryData> mapHistoryDatas = UtilityMethod.JsonDeserializeObject<List<MapHistoryData>>(maphistorydatas);
            if (mapHistoryDatas != null)
            {
                m_pMapHistoryDatas = mapHistoryDatas;
            }

            string totalmedalcounts = Convert.ToString(dataRow["totalmedalcounts"]);
            List<int> totalMedalCounts = UtilityMethod.JsonDeserializeObject<List<int>>(totalmedalcounts);
            if (totalMedalCounts != null)
            {
                m_tTotalMedalCounts = totalMedalCounts;
            }

            string weekmedalcounts = Convert.ToString(dataRow["weekmedalcounts"]);
            List<int> weekMedalCounts = UtilityMethod.JsonDeserializeObject<List<int>>(weekmedalcounts);
            if (weekMedalCounts != null)
            {
                m_tWeekMedalCounts = weekMedalCounts;
            }
        }
    }

    public override void DayRefresh()
    {
        base.DayRefresh();
        m_nTodayCompleteCount = 0;
        OnChangeData();
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyMapSystem resMsgBodyMapSystem = new ResMsgBodyMapSystem();
        resMsgBodyMapSystem.TodayCompleteCount = m_nTodayCompleteCount;
        resMsgBodyMapSystem.TotalCompleteCount = m_nTotalCompleteCount;

        foreach (var item in m_pWinningStreaks)
        {
            WinningStreakData winningStreakData = new WinningStreakData()
            {
                MapType = item.Key,
                Count = item.Value,
            };
            resMsgBodyMapSystem.WinningStreaks.Add(winningStreakData);
        }

        foreach (var item in m_pMapHistoryDatas)
        {
            resMsgBodyMapSystem.MapHistoryDatas.Add(item);
        }
        return resMsgBodyMapSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();
        AddSaveCache("totalcompletecount", m_nTotalCompleteCount);
        AddSaveCache("todaycompletecount", m_nTodayCompleteCount);
        // 兼容老版本
        Dictionary<MapTypeServer, int> winningstreaks = new Dictionary<MapTypeServer, int>();
        foreach (var item in m_pWinningStreaks)
        {
            winningstreaks.Add((MapTypeServer)item.Key, item.Value);
        }
        AddSaveCache("winningstreaks", UtilityMethod.JsonSerializeObject(winningstreaks));
        AddSaveCache("maphistorydatas", UtilityMethod.JsonSerializeObject(m_pMapHistoryDatas));
        AddSaveCache("totalmedalcounts", UtilityMethod.JsonSerializeObject(m_tTotalMedalCounts));
        AddSaveCache("weekmedalcounts", UtilityMethod.JsonSerializeObject(m_tWeekMedalCounts));
    }

    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 获取连胜次数
    /// </summary>
    /// <param name="i_eMapType"></param>
    /// <returns></returns>
    public int GetWinningStreakCount(MapType i_eMapType)
    {
        m_pWinningStreaks.TryGetValue(i_eMapType, out int value);
        return value;
    }

    /// <summary>
    /// 进入比赛
    /// </summary>
    /// <param name="i_nMapCfgId"></param>
    public void EnterCompetitionMap(int i_nMapCfgId)
    {
        Map_Data map_Data = ConfigManager.Map.Get(i_nMapCfgId);
        if (map_Data == null)
        {
            return;
        }

        this.GetSystem<TaskSystem>().TriggerTaskEventAddValue(TaskEventEnum.ePlayMap, 1, new List<int>() { i_nMapCfgId });

        if (this.GetSystem<EnergySystem>().IsEnergyEnough(map_Data.CostEnergy) && this.GetSystem<ItemSystem>().IsCostItem(map_Data.CostItems))
        {
            this.GetSystem<EnergySystem>().CostEnergy(map_Data.CostEnergy);
            this.GetSystem<ItemSystem>().CostItem(map_Data.CostItems);
            m_bIsCost = true;
        }
    }

    /// <summary>
    /// 完成比赛
    /// </summary>
    /// <param name="i_nMapCfgId"></param>
    /// <param name="i_nRank"></param>
    /// <param name="i_nTime"></param>
    public void CompleteCompetitionMap(int i_nMapCfgId, int i_nRank, int i_nTime)
    {
        Map_Data map_Data = ConfigManager.Map.Get(i_nMapCfgId);
        if (map_Data == null)
        {
            return;
        }

        if (!m_bIsCost)
        {
            return;
        }
        m_bIsCost = false;

        MapType mapType = (MapType)map_Data.SceneType;
        long addLeagueXP = 0;

        if (!m_pWinningStreaks.ContainsKey(mapType))
        {
            m_pWinningStreaks.Add(mapType, 0);
        }

        if (i_nRank > 0 && i_nRank <= 3)
        {
            m_pWinningStreaks[mapType]++;

            if (mapType == MapType.PvpRankingMap)
            {
                m_tTotalMedalCounts[i_nRank - 1]++;
                if (SeasonManager.Instance.IsSeasonMedalStart())
                {
                    m_tWeekMedalCounts[i_nRank - 1]++;
                    List<long> rankValues = new List<long> { 0, 0, 0 };
                    for (int i = 0; i < m_tWeekMedalCounts.Count; i++)
                    {
                        rankValues[i] = m_tWeekMedalCounts[i];
                    }
                    RankManager.Instance.OnChangeRankValue(RankTypeEnum.SeasonMedal, this.GetPlayer().GetRoleId(), rankValues, this.GetPlayer());
                }
            }
        }
        else
        {
            m_pWinningStreaks[mapType] = 0;
        }

        if (i_nRank <= 0)
        {
            // 失败
            switch (mapType)
            {
                case MapType.PveMap:
                    break;
                case MapType.PvpRankingMap:
                    addLeagueXP = this.GetSystem<SeasonSystem>().SettlementAward(i_nMapCfgId, i_nRank, GetWinningStreakCount(mapType));
                    break;
            }
        }
        else
        {
            // 胜利
            TaskSystem taskSystem = this.GetSystem<TaskSystem>();
            taskSystem.TriggerTaskEventAddValue(TaskEventEnum.eAccomplishGame, 1);
            if (i_nRank == 1)
            {
                taskSystem.TriggerTaskEventAddValue(TaskEventEnum.eChampionship, 1);
            }

            switch (mapType)
            {
                case MapType.PveMap:
                    if (i_nRank > 0)
                    {
                        if (i_nRank == 1)
                        {
                            taskSystem.TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent122, 1, new List<int>() { i_nMapCfgId });
                        }

                        if (m_nTodayCompleteCount < ConfigManager.Param.Get("EverydayMapGetGoldCount").IntParam && i_nRank > 0)
                        {
                            int[] raceRewardMultiplier = ConfigManager.Param.Get("RaceRewardMultiplier").IntParams;
                            if (raceRewardMultiplier.Length > i_nRank)
                            {
                                if (map_Data.AwardItem != null)
                                {
                                    this.GetSystem<ItemSystem>().AddItem(map_Data.AwardItem, raceRewardMultiplier[i_nRank - 1]);
                                }
                            }
                        }
                        m_nTodayCompleteCount++;
                        m_nTotalCompleteCount++;
                    }
                    break;
                case MapType.PvpRankingMap:
                    if (SeasonManager.Instance.IsStateInSeason())
                    {
                        addLeagueXP = this.GetSystem<SeasonSystem>().SettlementAward(i_nMapCfgId, i_nRank, GetWinningStreakCount(mapType));
                    }
                    taskSystem.TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent123, 1);
                    break;
            }
        }

        if (mapType == MapType.PvpRankingMap)
        {
            MapHistoryData mapHistoryData = new MapHistoryData()
            {
                MapCfgId = i_nMapCfgId,
                Rank = i_nRank,
                LeagueXP = addLeagueXP,
                Time = i_nTime,
                RecordTime = UtilityMethod.GetUnixTimeMilliseconds(),
                RoleCfgId = this.GetSystem<BaseInfoSystem>().GetRoleCfgId(),
                CarCfgId = this.GetSystem<BaseInfoSystem>().GetCarCfgId(),
            };
            if (m_pMapHistoryDatas.Count >= 20)
            {
                m_pMapHistoryDatas.RemoveAt(0);
            }
            m_pMapHistoryDatas.Add(mapHistoryData);
        }

        OnChangeData();
        Debug.Instance.Log($"MapSystem CompleteCompetitionMap -> RoleId({this.GetPlayer().GetRoleId()}) TodayCompleteCount({m_nTodayCompleteCount} TotalCompleteCount({m_nTotalCompleteCount})", LogType.system);
    }

    /// <summary>
    /// 清理周奖牌
    /// </summary>
    public void ClearWeekMedalCounts()
    {
        m_tWeekMedalCounts = new List<int> { 0, 0, 0 };
        AddSaveCache("weekmedalcounts", UtilityMethod.JsonSerializeObject(m_tWeekMedalCounts));
    }
}