public partial class CarUpgrade_Data
{
    public long[] Costs;
    public int[][] CostItems;
    public int[] Scorings;

    public void InitCosts()
    {
        lock (this)
        {
            Costs = new long[5] { 0, this.Cost1, this.Cost2, this.Cost3, this.Cost4 };
            CostItems = new int[5][] { [], this.CostItem1, this.CostItem2, this.CostItem3, this.CostItem4 };
            Scorings = new int[5] { 0, this.Scoring1, this.Scoring2, this.Scoring3, this.Scoring4 };
        }
    }
}

public partial class CarUpgrade_Table : BaseTable
{
    public override void InitExtend()
    {
        for (int i = 0; i < Count; i++)
        {
            this.GetItem(i).InitCosts();
        }
    }
}
