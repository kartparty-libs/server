public partial class KartKey_Data
{
}

public partial class KartKey_Table : BaseTable
{
    public static List<RobotCountData> RobotRankCountMapping = new List<RobotCountData>();
    public static Dictionary<int, KartKey_Data> RobotRankDataMapping = new Dictionary<int, KartKey_Data>();
    private readonly object lockObject = new object();
    public override void InitExtend()
    {
        int extendCarCount = 0;
        int extendDiamondCount = 0;
        int extendTotalCount = 0;
        lock (lockObject)
        {
            RobotRankCountMapping.Clear();
            RobotRankDataMapping.Clear();
            for (int i = 0; i < this.Count; i++)
            {
                KartKey_Data kartKey_Data = GetItem(i);
                if (kartKey_Data.IsRobot == 1 && kartKey_Data.RobotRank > 0)
                {
                    RobotCountData robotTable = new RobotCountData();
                    robotTable.rank = kartKey_Data.RobotRank;
                    if (kartKey_Data.RobotMiningType == 1)
                    {
                        extendDiamondCount++;
                    }
                    else if (kartKey_Data.RobotMiningType == 2)
                    {
                        extendCarCount++;
                    }
                    else if (kartKey_Data.RobotMiningType == 3)
                    {
                        extendCarCount++;
                        extendDiamondCount++;
                    }
                    extendTotalCount++;
                    robotTable.extendCarCount = extendCarCount;
                    robotTable.extendDiamondCount = extendDiamondCount;
                    robotTable.extendTotalCount = extendTotalCount;

                    RobotRankCountMapping.Add(robotTable);
                    RobotRankDataMapping.Add(kartKey_Data.RobotRank, kartKey_Data);
                }
            }
        }
    }
}

public struct RobotCountData
{
    public int rank;
    public int extendCarCount;
    public int extendDiamondCount;
    public int extendTotalCount;
}