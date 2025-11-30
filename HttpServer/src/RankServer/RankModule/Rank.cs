using Proto;
using System.Collections.Concurrent;
using System.Data;

/// <summary>
/// 常规排行榜
/// </summary>
public class Rank : IRank
{
    /// <summary>
    /// 存盘脏位
    /// </summary>
    protected ConcurrentDictionary<long, Dictionary<string, object>> m_pSaveCachesInsert = new ConcurrentDictionary<long, Dictionary<string, object>>();
    protected ConcurrentDictionary<long, Dictionary<string, object>> m_pSaveCachesUpdate = new ConcurrentDictionary<long, Dictionary<string, object>>();

    /// <summary>
    /// 排行类型
    /// </summary>
    public RankTypeEnum RankTypeEnum { get; protected set; }

    /// <summary>
    /// 排行数据库名
    /// </summary>
    protected string m_sRankTableName;

    /// <summary>
    /// 排行备份数据库名
    /// </summary>
    protected string m_sRankTableNameBackup;

    /// <summary>
    /// 排行值数量
    /// </summary>
    protected int m_nValueCount;

    /// <summary>
    /// 排行榜数据
    /// </summary>
    protected ConcurrentDictionary<long, RankData> m_tRankDatas = new ConcurrentDictionary<long, RankData>();

    /// <summary>
    /// 排行榜数据快照
    /// </summary>
    protected List<RankData> m_tRankSnapshots = new List<RankData>();

    /// <summary>
    /// 排行榜数据备份
    /// </summary>
    //protected List<RankData> m_tRankBaskups = new List<RankData>();

    /// <summary>
    /// 下次排行榜快照时间戳
    /// </summary>
    protected long m_nNextRankSnapshotTime = 0;

    /// <summary>
    /// 排行榜快照时间配置
    /// </summary>
    protected long[] m_tNextRankSnapshotTimes;

    /// <summary>
    /// 是否快照排行保存中
    /// </summary>
    protected bool m_bIsSaveRankSnapshot = false;

    /// <summary>
    /// 是否备份排行保存中
    /// </summary>
    protected bool m_bIsSaveRankBackup = false;

    /// <summary>
    /// 新赛季是否清空排行榜
    /// </summary>
    protected bool m_bNewSeasonClear = false;

    public Rank(RankTypeEnum i_eRankTypeEnum, string i_sSqlTableName, int i_nValueCount, bool i_bNewSeasonClear)
    {
        RankTypeEnum = i_eRankTypeEnum;
        m_sRankTableName = i_sSqlTableName;
        m_sRankTableNameBackup = i_sSqlTableName + "_backup";
        m_nValueCount = i_nValueCount;
        m_bNewSeasonClear = i_bNewSeasonClear;

        Rank_Data rank_Data = ConfigManager.Rank.Get((int)RankTypeEnum);
        m_tNextRankSnapshotTimes = new long[rank_Data.RankSnapshotTime.Length];
        for (int i = 0; i < rank_Data.RankSnapshotTime.Length; i++)
        {
            string[] times = rank_Data.RankSnapshotTime[i].Split(':');
            if (times.Length == 2)
            {
                int hour = Convert.ToInt32(times[0]);
                int minute = Convert.ToInt32(times[1]);
                m_tNextRankSnapshotTimes[i] = (hour * 60 + minute) * 60000;
            }
        }

        if (Launch.DBServer.IsHasTable(ServerTypeEnum.eRankServer, m_sRankTableName))
        {
            DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eRankServer, m_sRankTableName);
            if (data != null && data.Rows.Count > 0)
            {
                for (int i = 0; i < data.Rows.Count; i++)
                {
                    DataRow dataRow = data.Rows[i];
                    RankData rankData = new RankData();
                    rankData.key = Convert.ToInt64(dataRow["rankkey"]);

                    for (int j = 0; j < m_nValueCount; j++)
                    {
                        long rankvalue = Convert.ToInt64(dataRow[$"rankvalue{j}"]);
                        rankData.values.Add(rankvalue);
                    }
                    rankData.time = Convert.ToInt64(dataRow["time"]);
                    rankData.otherInfo = Convert.ToString(dataRow["otherinfo"]);
                    m_tRankDatas.TryAdd(rankData.key, rankData);
                }
            }
        }
        else
        {
            string rankCreateSql =
                $"CREATE TABLE `{m_sRankTableName}` (\r\n" +
                $" `rankkey` bigint(20) NOT NULL COMMENT '排行键',\r\n ";
            for (int j = 0; j < m_nValueCount; j++)
            {
                rankCreateSql += $" `rankvalue{j}` bigint(20) NOT NULL COMMENT '排行值{j}',\r\n ";
            }
            rankCreateSql += $" `time` bigint(20) NOT NULL COMMENT '排行值最早达成时间戳',\r\n " +
            $" `otherinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '其他信息',\r\n " +
            $" PRIMARY KEY (`rankkey`)\r\n" +
            $") ENGINE=InnoDB DEFAULT CHARSET=utf8;";

            Launch.DBServer.ExecuteNonQuery(ServerTypeEnum.eRankServer, rankCreateSql);
        }

        if (!Launch.DBServer.IsHasTable(ServerTypeEnum.eRankServer, m_sRankTableNameBackup))
        {
            string rankCreateSqlBackup =
            $"CREATE TABLE `{m_sRankTableNameBackup}` (\r\n" +
            $" `rankkey` bigint(20) NOT NULL COMMENT '排行键',\r\n ";
            for (int j = 0; j < m_nValueCount; j++)
            {
                rankCreateSqlBackup += $" `rankvalue{j}` bigint(20) NOT NULL COMMENT '排行值{j}',\r\n ";
            }
            rankCreateSqlBackup += $" `time` bigint(20) NOT NULL COMMENT '排行值最早达成时间戳',\r\n " +
            $" `otherinfo` varchar(2048) NOT NULL DEFAULT '' COMMENT '其他信息',\r\n " +
            $" PRIMARY KEY (`rankkey`)\r\n" +
            $") ENGINE=InnoDB DEFAULT CHARSET=utf8;";

            Launch.DBServer.ExecuteNonQuery(ServerTypeEnum.eRankServer, rankCreateSqlBackup);
        }
    }

    public virtual void Initializer()
    {
        RankSnapshot();
        GetRankData(100000001, 0, 0);
        //Dictionary<string, bool> orderByColumns = new Dictionary<string, bool>();
        //for (int i = 0; i < m_nValueCount; i++)
        //{
        //    orderByColumns.Add($"rankvalue{i}", false);
        //}
        //orderByColumns.Add("time", true);
        //DataTable data = Launch.DBServer.SelectDataWithMultiOrder(ServerTypeEnum.eRankServer, m_sRankTableNameBackup, orderByColumns);
        //List<RankData> rankSnapshots = new List<RankData>();
        //int rank = 0;
        //if (data != null && data.Rows.Count > 0)
        //{
        //    for (int i = 0; i < data.Rows.Count; i++)
        //    {
        //        rank++;
        //        DataRow dataRowCurr = data.Rows[i];
        //        RankData rankDataCurr = new RankData();
        //        rankDataCurr.key = Convert.ToInt64(dataRowCurr["rankkey"]);
        //        for (int j = 0; j < m_nValueCount; j++)
        //        {
        //            long rankvalue = Convert.ToInt64(dataRowCurr[$"rankvalue{j}"]);
        //            rankDataCurr.values.Add(rankvalue);
        //        }
        //        rankDataCurr.time = Convert.ToInt64(dataRowCurr["time"]);
        //        rankDataCurr.otherInfo = Convert.ToString(dataRowCurr["otherinfo"]);
        //        rankDataCurr.rank = rank;
        //        rankSnapshots.Add(rankDataCurr);
        //    }
        //}

        //if (rankSnapshots.Count > 0)
        //{
        //    m_tRankBaskups = new List<RankData>(rankSnapshots);
        //    rankSnapshots.Clear();
        //}
    }

    public virtual void Update(int i_nMillisecondDelay)
    {
        if (m_nNextRankSnapshotTime != 0 && m_nNextRankSnapshotTime <= UtilityMethod.GetUnixTimeMilliseconds())
        {
            RankSnapshot();
        }
    }

    public virtual void SaveData()
    {
        if (m_pSaveCachesInsert.Count > 0)
        {
            Dictionary<long, Dictionary<string, object>> saveCachesInsert = new Dictionary<long, Dictionary<string, object>>();
            lock (this)
            {
                saveCachesInsert = m_pSaveCachesInsert.ToDictionary();
                m_pSaveCachesInsert.Clear();
            }
            foreach (var item in saveCachesInsert)
            {
                Launch.DBServer.InsertData(ServerTypeEnum.eRankServer, m_sRankTableName, item.Value);
                //Debug.Instance.Log($"Rank SaveData  InsertData -> key = {item.Key}  value = {item.Value["rankvalue"]}");
            }
        }

        if (m_pSaveCachesUpdate.Count > 0)
        {
            Dictionary<long, Dictionary<string, object>> saveCachesUpdate = new Dictionary<long, Dictionary<string, object>>();
            lock (this)
            {
                saveCachesUpdate = m_pSaveCachesUpdate.ToDictionary();
                m_pSaveCachesUpdate.Clear();
            }
            foreach (var item in saveCachesUpdate)
            {
                Launch.DBServer.UpdateData(ServerTypeEnum.eRankServer, m_sRankTableName, item.Value, "rankkey", item.Key);
                //Debug.Instance.Log($"Rank SaveData UpdateData -> key = {item.Key}  value = {item.Value["rankvalue"]}");
            }
        }
    }

    public virtual void OnChangeData(SqlHandleEnum i_eSqlHandleEnum, long i_nKey, Dictionary<string, object> i_pSaveRankData)
    {
        if (i_eSqlHandleEnum == SqlHandleEnum.eInsert)
        {
            m_pSaveCachesInsert.AddOrUpdate(i_nKey, i_pSaveRankData, (key, oldValue) => { return i_pSaveRankData; });
        }
        else if (i_eSqlHandleEnum == SqlHandleEnum.eUpdate)
        {
            if (m_pSaveCachesInsert.ContainsKey(i_nKey))
            {
                m_pSaveCachesInsert.AddOrUpdate(i_nKey, i_pSaveRankData, (key, oldValue) => { return i_pSaveRankData; });
            }
            else
            {
                m_pSaveCachesUpdate.AddOrUpdate(i_nKey, i_pSaveRankData, (key, oldValue) => { return i_pSaveRankData; });
            }
        }
        //Debug.Instance.Log($"Rank OnChangeData -> key = {i_nKey}  value = {i_pSaveRankData["rankvalue"]}");
    }

    protected Dictionary<string, object> GetSaveRankData(RankData i_pRankData)
    {
        Dictionary<string, object> saveData = new Dictionary<string, object>();
        saveData.Add("rankkey", i_pRankData.key);
        for (int j = 0; j < m_nValueCount; j++)
        {
            if (i_pRankData.values.Count > j)
            {
                saveData.Add($"rankvalue{j}", i_pRankData.values[j]);
            }
        }
        saveData.Add("time", i_pRankData.time);
        saveData.Add("otherinfo", i_pRankData.otherInfo);
        return saveData;
    }

    /// <summary>
    /// 开始新赛季
    /// </summary>
    public virtual void StartNewSeason(int i_nNewSeasonId)
    {
        if (m_bNewSeasonClear)
        {
            ClearRankData();
        }
    }
    // ---------------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 更新排行数据
    /// </summary>
    /// <param name="i_nKey"></param>
    /// <param name="i_tValues"></param>
    /// <param name="i_sOtherInfo"></param>
    public virtual void UpdateRankData(long i_nKey, List<long> i_tValues, string i_sOtherInfo)
    {
        SqlHandleEnum sqlHandleEnum = SqlHandleEnum.eUpdate;
        Dictionary<string, object> changeData = new Dictionary<string, object>();
        m_tRankDatas.AddOrUpdate(i_nKey, (key) =>
       {
           RankData rankData = new RankData();
           rankData.key = i_nKey;
           rankData.values = i_tValues;
           rankData.time = UtilityMethod.GetUnixTimeMilliseconds();
           rankData.otherInfo = i_sOtherInfo;
           sqlHandleEnum = SqlHandleEnum.eInsert;
           changeData = GetSaveRankData(rankData);
           //Debug.Instance.Log($"Rank UpdateRankData key = {rankData.key}  value = {rankData.value}");
           return rankData;
       }, (key, rankData) =>
       {
           for (int i = 0; i < rankData.values.Count; i++)
           {
               if (rankData.values[i] < i_tValues[i])
               {
                   rankData.values[i] = i_tValues[i];
                   rankData.time = UtilityMethod.GetUnixTimeMilliseconds();
               }
           }
           rankData.otherInfo = i_sOtherInfo;
           changeData = GetSaveRankData(rankData);
           //Debug.Instance.Log($"Rank UpdateRankData key = {rankData.key}  value = {rankData.value}");
           return rankData;
       });
        OnChangeData(sqlHandleEnum, i_nKey, changeData);
    }

    /// <summary>
    /// 排行榜快照处理
    /// </summary>
    public void RankSnapshot()
    {
        SaveData();

        Dictionary<string, bool> orderByColumns = new Dictionary<string, bool>();
        for (int i = 0; i < m_nValueCount; i++)
        {
            orderByColumns.Add($"rankvalue{i}", false);
        }
        orderByColumns.Add("time", true);
        DataTable data = Launch.DBServer.SelectDataWithMultiOrder(ServerTypeEnum.eRankServer, m_sRankTableName, orderByColumns);
        List<RankData> rankSnapshots = new List<RankData>();
        int rank = 0;
        if (data != null && data.Rows.Count > 0)
        {
            for (int i = 0; i < data.Rows.Count; i++)
            {
                rank++;
                DataRow dataRowCurr = data.Rows[i];
                RankData rankDataCurr = new RankData();
                rankDataCurr.key = Convert.ToInt64(dataRowCurr["rankkey"]);
                for (int j = 0; j < m_nValueCount; j++)
                {
                    long rankvalue = Convert.ToInt64(dataRowCurr[$"rankvalue{j}"]);
                    rankDataCurr.values.Add(rankvalue);
                }
                rankDataCurr.time = Convert.ToInt64(dataRowCurr["time"]);
                rankDataCurr.otherInfo = Convert.ToString(dataRowCurr["otherinfo"]);
                rankDataCurr.rank = rank;
                rankSnapshots.Add(rankDataCurr);
                if (m_tRankDatas.TryGetValue(rankDataCurr.key, out RankData _rankDataCurr))
                {
                    lock (this)
                    {
                        _rankDataCurr.rank = rankDataCurr.rank;
                    }
                }

                //Debug.Instance.Log($"RankSnapshot {m_sRankTableName} -> rank = {rankData.rank} key = {rankData.key} value = {rankData.value} time = {rankData.time} otherInfo = {rankData.otherInfo}");
            }
        }

        if (rankSnapshots.Count > 0)
        {
            lock (this)
            {
                m_tRankSnapshots = new List<RankData>(rankSnapshots);
            }
            rankSnapshots.Clear();
        }

        UpdateNextRankSnapshotTime();
        //BackupRankData();
    }

    /// <summary>
    /// 更新下次排行榜快照时间戳
    /// </summary>
    protected void UpdateNextRankSnapshotTime()
    {
        int num = 0;
        while (true)
        {
            if (CommonRankManager.Instance.ZeroTime == 0 || m_tNextRankSnapshotTimes.Length == 0)
            {
                m_nNextRankSnapshotTime = 0;
                return;
            }

            if (m_nNextRankSnapshotTime == 0)
            {
                m_nNextRankSnapshotTime = UtilityMethod.GetUnixTimeMilliseconds();
            }

            foreach (var item in m_tNextRankSnapshotTimes)
            {
                long nextTime = CommonRankManager.Instance.ZeroTime + item + num * 86400000;
                if (m_nNextRankSnapshotTime < nextTime)
                {
                    m_nNextRankSnapshotTime = nextTime;
                    return;
                }
            }
            num++;
        }
    }

    /// <summary>
    /// 备份排行榜数据
    /// </summary>
    //public void BackupRankData()
    //{
    //    if (m_bIsSaveRankBackup)
    //    {
    //        return;
    //    }
    //    m_bIsSaveRankBackup = true;

    //    List<RankData> rankSnapshots = new List<RankData>();
    //    lock (this)
    //    {
    //        rankSnapshots = m_tRankSnapshots.ToList();
    //    }

    //    if (rankSnapshots.Count > 0)
    //    {
    //        Launch.DBServer.DeleteAllDataFromTable(ServerTypeEnum.eRankServer, m_sRankTableNameBackup);

    //        for (int i = 0; i < rankSnapshots.Count; i++)  
    //        {
    //            RankData rankData = rankSnapshots[i];
    //            Dictionary<string, object> columnValues = new Dictionary<string, object>()
    //            {
    //                ["rankkey"] = rankData.key,
    //                ["time"] = rankData.time,
    //                ["otherinfo"] = rankData.otherInfo,
    //            };
    //            for (int j = 0; j < rankData.values.Count; j++)
    //            {
    //                columnValues.Add($"rankvalue{j}", rankData.values[j]);
    //            }
    //            Launch.DBServer.InsertData(ServerTypeEnum.eRankServer, m_sRankTableNameBackup, columnValues);
    //        }
    //    }

    //    if (rankSnapshots.Count > 0)
    //    {
    //        m_tRankBaskups = new List<RankData>(rankSnapshots);
    //        rankSnapshots.Clear();
    //    }

    //    m_bIsSaveRankBackup = false;
    //}

    /// <summary>
    /// 获取排行榜数据
    /// </summary>
    /// <param name="i_nSelfKey"></param>
    /// <param name="i_nRankStartIndex"></param>
    /// <param name="i_nRankEndIndex"></param>
    /// <returns></returns>
    public ResMsgBodyCommonRankManager GetRankData(long i_nSelfKey, int i_nRankStartIndex, int i_nRankEndIndex)
    {
        ResMsgBodyCommonRankManager resMsgBodyCommonRankManager = new ResMsgBodyCommonRankManager();
        resMsgBodyCommonRankManager.RankTypeEnum = RankTypeEnum;
        resMsgBodyCommonRankManager.NextUpdateTime = m_nNextRankSnapshotTime;

        int rankCount = m_tRankSnapshots.Count;
        if (rankCount == 0)
        {
            return resMsgBodyCommonRankManager;
        }

        if (m_tRankDatas.TryGetValue(i_nSelfKey, out RankData selfRankData))
        {
            if (selfRankData.rank > 0 && m_tRankSnapshots.Count >= selfRankData.rank)
            {
                RankData rankData = m_tRankSnapshots[selfRankData.rank - 1];
                resMsgBodyCommonRankManager.SelfRankData = new ResMsgBodyRankData();
                resMsgBodyCommonRankManager.SelfRankData.Key = rankData.key;
                for (int i = 0; i < rankData.values.Count; i++)
                {
                    resMsgBodyCommonRankManager.SelfRankData.Values.Add(rankData.values[i]);
                }
                resMsgBodyCommonRankManager.SelfRankData.Time = rankData.time;
                resMsgBodyCommonRankManager.SelfRankData.Rank = rankData.rank;
                resMsgBodyCommonRankManager.SelfRankData.OtherInfo = rankData.otherInfo;
            }
        }

        if (i_nRankEndIndex >= 0)
        {
            int startIndex = Math.Min(i_nRankStartIndex, rankCount);
            int endIndex = Math.Min(i_nRankEndIndex + 1, rankCount);

            List<RankData> rankDataList;
            lock (this)
            {
                rankDataList = m_tRankSnapshots.GetRange(startIndex, endIndex - startIndex);
                foreach (var item in rankDataList)
                {
                    ResMsgBodyRankData resMsgBodyRankData = new ResMsgBodyRankData();
                    resMsgBodyRankData.Key = item.key;
                    for (int i = 0; i < item.values.Count; i++)
                    {
                        resMsgBodyRankData.Values.Add(item.values[i]);
                    }
                    resMsgBodyRankData.Time = item.time;
                    resMsgBodyRankData.Rank = item.rank;
                    resMsgBodyRankData.OtherInfo = item.otherInfo;
                    resMsgBodyCommonRankManager.RankDataList.Add(resMsgBodyRankData);
                }
            }
        }
        return resMsgBodyCommonRankManager;
    }

    /// <summary>
    /// 获取备份排行榜数据
    /// </summary>
    /// <param name="i_nSelfKey"></param>
    /// <param name="i_nRankStartIndex"></param>
    /// <param name="i_nRankEndIndex"></param>
    /// <returns></returns>
    //public ResMsgBodyCommonRankManager GetBackupRankData(long i_nSelfKey, int i_nRankStartIndex, int i_nRankEndIndex)
    //{
    //    ResMsgBodyCommonRankManager resMsgBodyCommonRankManager = new ResMsgBodyCommonRankManager();
    //    resMsgBodyCommonRankManager.RankTypeEnum = RankTypeEnum;
    //    resMsgBodyCommonRankManager.NextUpdateTime = 0;

    //    int rankCount = m_tRankBaskups.Count;
    //    if (rankCount == 0)
    //    {
    //        return resMsgBodyCommonRankManager;
    //    }

    //    DataTable data = Launch.DBServer.SelectData(ServerTypeEnum.eRankServer, m_sRankTableNameBackup, "rankkey", i_nSelfKey);
    //    if (data != null && data.Rows.Count > 0)
    //    {
    //        DataRow dataRow = data.Rows[0];
    //        RankData rankData = new RankData();
    //        rankData.key = Convert.ToInt64(dataRow["rankkey"]);

    //        for (int j = 0; j < m_nValueCount; j++)
    //        {
    //            long rankvalue = Convert.ToInt64(dataRow[$"rankvalue{j}"]);
    //            rankData.values.Add(rankvalue);
    //        }
    //        rankData.time = Convert.ToInt64(dataRow["time"]);
    //        rankData.otherInfo = Convert.ToString(dataRow["otherinfo"]);

    //        resMsgBodyCommonRankManager.SelfRankData = new ResMsgBodyRankData();
    //        resMsgBodyCommonRankManager.SelfRankData.Key = rankData.key;
    //        for (int i = 0; i < rankData.values.Count; i++)
    //        {
    //            resMsgBodyCommonRankManager.SelfRankData.Values.Add(rankData.values[i]);
    //        }
    //        resMsgBodyCommonRankManager.SelfRankData.Time = rankData.time;
    //        resMsgBodyCommonRankManager.SelfRankData.Rank = rankData.rank;
    //        resMsgBodyCommonRankManager.SelfRankData.OtherInfo = rankData.otherInfo;
    //    }

    //    if (i_nRankEndIndex != 0)
    //    {
    //        int startIndex = Math.Min(i_nRankStartIndex, rankCount);
    //        int endIndex = Math.Min(i_nRankEndIndex + 1, rankCount);

    //        List<RankData> rankDataList;
    //        lock (this)
    //        {
    //            rankDataList = m_tRankBaskups.GetRange(startIndex, endIndex - startIndex);
    //            foreach (var item in rankDataList)
    //            {
    //                ResMsgBodyRankData resMsgBodyRankData = new ResMsgBodyRankData();
    //                resMsgBodyRankData.Key = item.key;
    //                for (int i = 0; i < item.values.Count; i++)
    //                {
    //                    resMsgBodyRankData.Values.Add(item.values[i]);
    //                }
    //                resMsgBodyRankData.Time = item.time;
    //                resMsgBodyRankData.Rank = item.rank;
    //                resMsgBodyRankData.OtherInfo = item.otherInfo;
    //                resMsgBodyCommonRankManager.RankDataList.Add(resMsgBodyRankData);
    //            }
    //        }
    //    }
    //    return resMsgBodyCommonRankManager;
    //}

    /// <summary>
    /// 清空当前排行榜
    /// </summary>
    public void ClearRankData()
    {
        m_tRankDatas.Clear();
        m_tRankSnapshots.Clear();
        Launch.DBServer.DeleteAllDataFromTable(ServerTypeEnum.eRankServer, m_sRankTableName);
    }

    /// <summary>
    /// 清空备份排行榜
    /// </summary>
    //public void ClearBackupRankData()
    //{
    //    m_tRankBaskups.Clear();
    //    Launch.DBServer.DeleteAllDataFromTable(ServerTypeEnum.eRankServer, m_sRankTableNameBackup);
    //}
}

/// <summary>
/// 排行榜数据
/// </summary>
public class RankData()
{
    /// <summary>
    /// 排行键
    /// </summary>
    public long key = 0;
    /// <summary>
    /// 排行值
    /// </summary>
    public List<long> values = new List<long>();
    /// <summary>
    /// 排行值最早达成时间戳
    /// </summary>
    public long time = 0;
    /// <summary>
    /// 排名
    /// </summary>
    public int rank = -1;
    /// <summary>
    /// 其他信息
    /// </summary>
    public string otherInfo = "";
}