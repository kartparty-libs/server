using Proto;

public interface IRank
{
    public void Initializer();
    public void Update(int i_nMillisecondDelay);
    public void SaveData();

    /// <summary>
    /// 更新排行数据
    /// </summary>
    /// <param name="i_nKey"></param>
    /// <param name="i_tValues"></param>
    /// <param name="i_sOtherInfo"></param>
    public void UpdateRankData(long i_nKey, List<long> i_tValues, string i_sOtherInfo);

    /// <summary>
    /// 排行榜快照处理
    /// </summary>
    public void RankSnapshot();

    /// <summary>
    /// 保存排行快照
    /// </summary>
    //public void BackupRankData();
    
    /// <summary>
    /// 获取排行榜数据
    /// </summary>
    /// <param name="i_nSelfKey"></param>
    /// <param name="i_nRankStartIndex"></param>
    /// <param name="i_nRankEndIndex"></param>
    /// <returns></returns>
    public ResMsgBodyCommonRankManager GetRankData(long i_nSelfKey, int i_nRankStartIndex, int i_nRankEndIndex);

    /// <summary>
    /// 获取排行榜备份数据
    /// </summary>
    /// <param name="i_nSelfKey"></param>
    /// <param name="i_nRankStartIndex"></param>
    /// <param name="i_nRankEndIndex"></param>
    /// <returns></returns>
    //public ResMsgBodyCommonRankManager GetBackupRankData(long i_nSelfKey, int i_nRankStartIndex, int i_nRankEndIndex);

    /// <summary>
    /// 开始新赛季
    /// </summary>
    public void StartNewSeason(int i_nNewSeasonId)
    {
    }
}
