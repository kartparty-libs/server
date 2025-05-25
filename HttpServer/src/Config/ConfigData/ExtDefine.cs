public enum CarModuleType
{
    Car = 0,
    Module1,
    Module2,
    Module3,
    Module4,
}
public partial class CarMoudleProperty
{
    public int Id;
    public int Value;
}
public partial class ItemConfig
{
    public int ItemId;
    public int ItemCount;
    public int MaxCount;
}
// {{1,100},{2,200}}
public partial class CfgItemData
{
    public int Id;
    public long Count;
}