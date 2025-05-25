using System.Data;

public partial class ConfigManager
{
    public static Dictionary<string, IDataTable> ConfigTables = new Dictionary<string, IDataTable>();
    public static void Initializer()
    {
        InitTables();
        foreach (var item in _tables)
        {
            Load(item);
            ConfigTables.Add(item.GetTableName(), item);
        }
    }

    public static void Load(IDataTable dataTable)
    {
        // 使用Path.Combine来拼接路径，以确保跨平台兼容性  
        string tableName = dataTable.GetTableName();
        string jsonFilePath = Path.Combine("config", "logic", $"{tableName}.json");

        Debug.Instance.LogInfo($"ConfigManager Load -> {jsonFilePath}");

        try
        {
            // 读取文件内容  
            string jsonContent = File.ReadAllText(jsonFilePath);

            // 加载JSON到dataTable  
            dataTable.LoadJson(jsonContent);

            // 初始化扩展数据  
            dataTable.InitExtend();
        }
        catch (IOException ex)
        {
            // 处理文件读取可能发生的异常，例如文件不存在  
            Debug.Instance.LogError($"Error reading JSON file: {ex.Message}");
        }
        catch (Exception ex)
        {
            // 处理其他可能的异常  
            Debug.Instance.LogError($"Unexpected error occurred: {ex.Message}");
        }
    }

    public static void UpdateConfigTable(string tableName)
    {
        if (ConfigTables.TryGetValue(tableName, out IDataTable dataTable))
        {
            lock (dataTable)
            {
                Load(dataTable);
            }
        }
    }
}