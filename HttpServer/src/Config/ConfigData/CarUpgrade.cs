using System;
using System.Collections.Generic;
using Newtonsoft.Json;
public partial class CarUpgrade_Data
{
	public int Id;
	public long Cost1;
	public int[] CostItem1; 
	public int Scoring1;
	public long Cost2;
	public int[] CostItem2; 
	public int Scoring2;
	public long Cost3;
	public int[] CostItem3; 
	public int Scoring3;
	public long Cost4;
	public int[] CostItem4; 
	public int Scoring4;

}
public partial class CarUpgrade_Table : BaseTable
{
    public override string GetTableName() { return "CarUpgrade"; }
    private List<CarUpgrade_Data> DataList;
    public int Count {  get { return DataList.Count; } }
    public CarUpgrade_Data GetItem(int index)
    {
        if (index >= DataList.Count || index < 0) return null;
        return DataList[index];
    }
    public override void LoadJson(string json)
    {
        DataList = new List<CarUpgrade_Data>();
        var list = Newtonsoft.Json.JsonConvert.DeserializeObject<CarUpgrade_Data[]>(json);
        var len = list.Length;
        for (int i = 0; i < len; i++)
        {
            DataList.Add(list[i]);
        }
#if true
            PostLoadJson();
#endif
    }
    
#if true

    private Dictionary<int, int> _keyToIndex;
    private void PostLoadJson()
    {
        int len = DataList.Count;
		_keyToIndex = new Dictionary<int, int>(len);
		for (int i = 0;i < len; i++)
		{
			var item = DataList[i];
			var k = item.Id;
			if (!_keyToIndex.ContainsKey(k))
			{
				_keyToIndex.Add(k, i);
			}
			else
			{

			}
		}
    }
    public CarUpgrade_Data Get(int key)
    {
        if (_keyToIndex != null && _keyToIndex.TryGetValue(key, out int index))
        {
            return GetItem(index);
        }
        return null;
    }
#endif

}
