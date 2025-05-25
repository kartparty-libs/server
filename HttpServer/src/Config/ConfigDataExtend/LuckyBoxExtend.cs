public partial class LuckyBox_Data
{
}

public partial class LuckyBox_Table : BaseTable
{
    public static int TotalWeight;
    private readonly object lockObject = new object();
    public override void InitExtend()
    {
        lock (lockObject)
        {
            for (int i = 0; i < this.Count; i++)
            {
                TotalWeight += GetItem(i).Weight;
            }
        }
    }
}
