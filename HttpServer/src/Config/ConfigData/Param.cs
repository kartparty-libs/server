using System;
using System.Collections.Generic;
using Newtonsoft.Json;
public partial class Param_Data
{
	public string Id;
	public int IntParam;
	public int[] IntParams; 
	public string TextParam;

}
public partial class Param_Table : BaseTable
{
    public override string GetTableName() { return "Param"; }
    private List<Param_Data> DataList;
    public int Count {  get { return DataList.Count; } }
    public Param_Data GetItem(int index)
    {
        if (index >= DataList.Count || index < 0) return null;
        return DataList[index];
    }
    public override void LoadJson(string json)
    {
        DataList = new List<Param_Data>();
        var list = Newtonsoft.Json.JsonConvert.DeserializeObject<Param_Data[]>(json);
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

    private Dictionary<string, int> _keyToIndex;
    private void PostLoadJson()
    {
        int len = DataList.Count;
		_keyToIndex = new Dictionary<string, int>(len);
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
    public Param_Data Get(string key)
    {
        if (_keyToIndex != null && _keyToIndex.TryGetValue(key, out int index))
        {
            return GetItem(index);
        }
        return null;
    }
#endif

}
