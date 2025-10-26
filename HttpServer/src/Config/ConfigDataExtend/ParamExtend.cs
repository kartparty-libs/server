public partial class Param_Data
{
}
public struct SeasonMedalData
{
    public long time;
    public bool isStart;
}
public partial class Param_Table : BaseTable
{
    public static long MiningOpenTime = 0;
    public static long MiningCloseTime = 0;
    public static long OfflineEarningsTime = 0;
    public static int EnergyRecoverSpeed = int.MaxValue;

    public static List<SeasonMedalData> SeasonMedalTimes = new List<SeasonMedalData>();

    public override void InitExtend()
    {
        MiningOpenTime = UtilityMethod.ConvertToUtcTimestampMilliseconds(ConfigManager.Param.Get("MiningOpenTime").TextParam);
        MiningCloseTime = UtilityMethod.ConvertToUtcTimestampMilliseconds(ConfigManager.Param.Get("MiningCloseTime").TextParam);
        OfflineEarningsTime = ConfigManager.Param.Get("OfflineEarningsTime").IntParam * 3600000;
        EnergyRecoverSpeed = ConfigManager.Param.Get("EnergyRecoverSpeed").IntParam * 60000;
        string[] SeasonMedalStartTime = ConfigManager.Param.Get("SeasonMedalStartTime").TextParam.Split(",");
        string[] SeasonMedalEndTime = ConfigManager.Param.Get("SeasonMedalEndTime").TextParam.Split(",");
        SeasonMedalTimes = new List<SeasonMedalData>();
        for (int i = 0; i < SeasonMedalStartTime.Length; i++)
        {
            SeasonMedalData seasonMedalData1 = new SeasonMedalData()
            {
                time = UtilityMethod.ConvertToUtcTimestampMilliseconds(SeasonMedalStartTime[i], "yyyyMMddHHmm"),
                isStart = true,
            };
            SeasonMedalTimes.Add(seasonMedalData1);

            SeasonMedalData seasonMedalData2 = new SeasonMedalData()
            {
                time = UtilityMethod.ConvertToUtcTimestampMilliseconds(SeasonMedalEndTime[i], "yyyyMMddHHmm"),
                isStart = false,
            };
            SeasonMedalTimes.Add(seasonMedalData2);
        }
    }
}
