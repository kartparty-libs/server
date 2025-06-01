using Google.Protobuf;
using Proto;
using System.ComponentModel;
using System.Data;

/// <summary>
/// 任务系统
/// </summary>
public class TaskSystem : BasePlayerSystem
{
    /// <summary>
    /// 任务数据列表
    /// </summary>
    protected Dictionary<int, TaskData> m_pTaskDatas = new Dictionary<int, TaskData>();

    /// <summary>
    /// 任务类型映射列表
    /// </summary>
    protected Dictionary<TaskTypeEnum, List<int>> m_pTaskTypeMapping = new Dictionary<TaskTypeEnum, List<int>>();

    /// <summary>
    /// 任务事件映射列表
    /// </summary>
    protected Dictionary<TaskEventEnum, List<int>> m_pTaskEventMapping = new Dictionary<TaskEventEnum, List<int>>();

    /// <summary>
    /// 任务完成次数记录
    /// </summary>
    protected Dictionary<int, int> m_pTaskCompleteRecord = new Dictionary<int, int>();

    public TaskSystem(Player i_pPlayer, PlayerSystemManager i_pPlayerSystemManager) : base(i_pPlayer, i_pPlayerSystemManager)
    {
        for (int i = 0; i < ConfigManager.Task.Count; i++)
        {
            Task_Data taskCfgData = ConfigManager.Task.GetItem(i);
            m_pTaskDatas.Add(taskCfgData.Id, CreateTaskData(taskCfgData.Id));

            if (!m_pTaskTypeMapping.ContainsKey((TaskTypeEnum)taskCfgData.TaskType))
            {
                m_pTaskTypeMapping.Add((TaskTypeEnum)taskCfgData.TaskType, new List<int>());
            }
            m_pTaskTypeMapping[(TaskTypeEnum)taskCfgData.TaskType].Add(taskCfgData.Id);

            if (!m_pTaskEventMapping.ContainsKey((TaskEventEnum)taskCfgData.TaskEvent))
            {
                m_pTaskEventMapping.Add((TaskEventEnum)taskCfgData.TaskEvent, new List<int>());
            }
            m_pTaskEventMapping[(TaskEventEnum)taskCfgData.TaskEvent].Add(taskCfgData.Id);
        }
    }

    public override string GetSqlTableName() => SqlTableName.role_taskinfo;

    public override void Initializer(bool i_bIsNewPlayer)
    {
        base.Initializer(i_bIsNewPlayer);

        DataTable data = GetSystemSqlDataTable();
        if (data != null && data.Rows.Count > 0)
        {
            DataRow dataRow = data.Rows[0];
            string taskinfo = Convert.ToString(dataRow["taskinfo"]);
            if (taskinfo != null)
            {
                List<List<string>> taskinfos = UtilityMethod.JsonDeserializeObject<List<List<string>>>(taskinfo);
                if (taskinfos != null)
                {
                    for (int i = 0; i < taskinfos.Count; i++)
                    {
                        List<string> taskList = taskinfos[i];
                        TaskData taskData = new TaskData()
                        {
                            taskCfgId = Convert.ToInt32(taskList[0]),
                            taskValue = Convert.ToInt64(taskList[1]),
                            isReceiveAward = Convert.ToBoolean(taskList[2] == "1"),
                        };
                        m_pTaskDatas[taskData.taskCfgId] = taskData;
                    }
                }
            }

            string completerecord = Convert.ToString(dataRow["completerecord"]);
            if (completerecord != null)
            {
                Dictionary<int, int> completerecords = UtilityMethod.JsonDeserializeObject<Dictionary<int, int>>(completerecord);
                if (completerecords != null)
                {
                    foreach (var item in completerecords)
                    {
                        m_pTaskCompleteRecord.Add(item.Key, item.Value);
                    }
                }
            }
        }

        if (i_bIsNewPlayer)
        {
            TriggerTaskEventSetValue(TaskEventEnum.eLogin, this.GetPlayer().GetLoginNum());
            TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent102, 1);
        }
    }

    public override void DayRefresh()
    {
        base.DayRefresh();
        foreach (int taskCfgId in m_pTaskTypeMapping[TaskTypeEnum.eDailyTask])
        {
            m_pTaskDatas[taskCfgId] = this.CreateTaskData(taskCfgId);
        }

        TriggerTaskEventSetValue(TaskEventEnum.eLogin, this.GetPlayer().GetLoginNum());
        TriggerTaskEventSetValue(TaskEventEnum.eTaskEvent102, 1);

        this.OnChangeData();
    }

    public override IMessage GetResMsgBody()
    {
        this.m_bIsNeedSendClient = false;

        ResMsgBodyTaskSystem resMsgBodyTaskSystem = new ResMsgBodyTaskSystem();
        foreach (var item in m_pTaskDatas)
        {
            resMsgBodyTaskSystem.TaskDatas.Add(GetClientTaskData(item.Value));
        }
        return resMsgBodyTaskSystem;
    }

    public override void OnChangeData()
    {
        base.OnChangeData();

        List<List<string>> taskinfo = new List<List<string>>();
        foreach (var item in m_pTaskDatas)
        {
            if (item.Value.taskValue != 0)
            {
                List<string> taskList = new List<string>() {
                    item.Value.taskCfgId.ToString(),
                    item.Value.taskValue.ToString(),
                    item.Value.isReceiveAward?"1":"0",
                };
                taskinfo.Add(taskList);
            }
        }

        AddSaveCache("taskinfo", UtilityMethod.JsonSerializeObject(taskinfo));
        AddSaveCache("completerecord", UtilityMethod.JsonSerializeObject(m_pTaskCompleteRecord));
    }

    public override void OnNewSeason(int i_nSeasonId)
    {
        base.OnNewSeason(i_nSeasonId);

        foreach (var item in m_pTaskDatas)
        {
            Task_Data taskCfgData = ConfigManager.Task.Get(item.Key);

            if (taskCfgData != null && taskCfgData.SeasonClear == 1)
            {
                item.Value.taskValue = 0;
                item.Value.isReceiveAward = false;
            }
        }

        OnChangeData();
    }
    // --------------------------------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// 创建任务数据
    /// </summary>
    /// <param name="i_nTaskCfgId"></param>
    /// <returns></returns>
    public TaskData CreateTaskData(int i_nTaskCfgId)
    {
        TaskData taskData = new TaskData()
        {
            taskCfgId = i_nTaskCfgId,
            taskValue = 0,
            isReceiveAward = false,
        };
        return taskData;
    }

    /// <summary>
    /// 获取任务数据
    /// </summary>
    /// <param name="i_nTaskCfgId"></param>
    /// <returns></returns>
    public TaskData GetTaskData(int i_nTaskCfgId)
    {
        if (m_pTaskDatas.TryGetValue(i_nTaskCfgId, out TaskData __taskData))
        {
            return __taskData;
        }
        return null;
    }

    /// <summary>
    /// 获取客户端所需任务数据
    /// </summary>
    /// <param name="i_nInstId"></param>
    /// <returns></returns>
    public ResTaskData GetClientTaskData(TaskData i_tTaskData)
    {
        ResTaskData resTaskData = new ResTaskData()
        {
            TaskCfgId = i_tTaskData.taskCfgId,
            TaskValue = i_tTaskData.taskValue,
            IsReceiveAward = i_tTaskData.isReceiveAward,
        };
        return resTaskData;
    }

    /// <summary>
    /// 获取任务数据集合
    /// </summary>
    /// <returns></returns>
    public Dictionary<int, TaskData> GetTaskDatas()
    {
        return m_pTaskDatas;
    }

    /// <summary>
    /// 触发任务事件 累加值
    /// </summary>
    /// <param name="i_eTaskEventEnum"></param>
    /// <param name="i_nAddTaskValue"></param>
    /// <param name="i_tTaskConditions"></param>
    public void TriggerTaskEventAddValue(TaskEventEnum i_eTaskEventEnum, long i_nAddTaskValue, List<int> i_tTaskConditions = null)
    {
        if (m_pTaskEventMapping.TryGetValue(i_eTaskEventEnum, out List<int> value))
        {
            foreach (var taskCfgId in value)
            {
                TaskData taskData = this.GetTaskData(taskCfgId);
                if (taskData != null && !this.IsCompleted(taskData) && this.CheckTaskCondition(taskCfgId, i_tTaskConditions))
                {
                    taskData.taskValue += i_nAddTaskValue;
                    Debug.Instance.Log($"TaskSystem TriggerTaskEventAddValue -> RoleId({this.GetPlayer().GetRoleId()}) TaskCfgId({taskCfgId}) TaskValue({taskData.taskValue})", LogType.system);
                    this.OnChangeData();
                }
            }
        }
    }

    /// <summary>
    /// 触发任务事件 设置值
    /// </summary>
    /// <param name="i_eTaskEventEnum"></param>
    /// <param name="i_nSetTaskValue"></param>
    /// <param name="i_tTaskConditions"></param>
    public void TriggerTaskEventSetValue(TaskEventEnum i_eTaskEventEnum, long i_nSetTaskValue, List<int> i_tTaskConditions = null)
    {
        if (m_pTaskEventMapping.TryGetValue(i_eTaskEventEnum, out List<int> value))
        {
            foreach (var taskCfgId in value)
            {
                TaskData taskData = this.GetTaskData(taskCfgId);
                if (taskData != null && !this.IsCompleted(taskData) && this.CheckTaskCondition(taskCfgId, i_tTaskConditions))
                {
                    taskData.taskValue = i_nSetTaskValue;
                    Debug.Instance.Log($"TaskSystem TriggerTaskEventSetValue -> RoleId({this.GetPlayer().GetRoleId()}) TaskCfgId({taskCfgId}) TaskValue({taskData.taskValue})", LogType.system);
                    this.OnChangeData();
                }
            }
        }
    }

    /// <summary>
    /// 检测任务条件是否通过
    /// </summary>
    /// <param name="i_nTaskCfgId"></param>
    /// <param name="i_tTaskConditions"></param>
    /// <returns></returns>
    public bool CheckTaskCondition(int i_nTaskCfgId, List<int>? i_tTaskConditions)
    {
        Task_Data taskCfgData = ConfigManager.Task.Get(i_nTaskCfgId);

        if (taskCfgData == null)
        {
            return true;
        }

        if (taskCfgData.TaskConditionParams.Length == 0)
        {
            return true;
        }

        if (i_tTaskConditions == null || i_tTaskConditions.Count == 0)
        {
            return false;
        }

        for (int i = 0; i < taskCfgData.TaskConditionParams.Length; i++)
        {
            if (i_tTaskConditions.Count < (i + 1))
            {
                return false;
            }
            switch ((TaskConditionTypeEnum)taskCfgData.TaskConditionTypes[i])
            {
                case TaskConditionTypeEnum.eEqual:
                    if (i_tTaskConditions[i] != taskCfgData.TaskConditionParams[i])
                    {
                        return false;
                    }
                    break;
                case TaskConditionTypeEnum.eLessThan:
                    if (i_tTaskConditions[i] >= taskCfgData.TaskConditionParams[i])
                    {
                        return false;
                    }
                    break;
                case TaskConditionTypeEnum.eLessEqual:
                    if (i_tTaskConditions[i] > taskCfgData.TaskConditionParams[i])
                    {
                        return false;
                    }
                    break;
                case TaskConditionTypeEnum.eGreaterThan:
                    if (i_tTaskConditions[i] <= taskCfgData.TaskConditionParams[i])
                    {
                        return false;
                    }
                    break;
                case TaskConditionTypeEnum.eGreaterEqual:
                    if (i_tTaskConditions[i] < taskCfgData.TaskConditionParams[i])
                    {
                        return false;
                    }
                    break;
                default:
                    return false;
            }
        }
        return true;
    }

    /// <summary>
    /// 任务是否已完成
    /// </summary>
    /// <param name="i_tTaskData"></param>
    /// <returns></returns>
    public bool IsCompleted(TaskData i_tTaskData)
    {
        if (i_tTaskData == null)
        {
            return false;
        }
        Task_Data taskCfgData = ConfigManager.Task.Get(i_tTaskData.taskCfgId);
        if (i_tTaskData.taskValue >= taskCfgData.TaskValueParam)
        {
            return true;
        }
        return false;
    }

    /// <summary>
    /// 任务是否已领取
    /// </summary>
    /// <param name="i_tTaskData"></param>
    /// <returns></returns>
    public bool IsReceiveAward(TaskData i_tTaskData)
    {
        if (i_tTaskData == null)
        {
            return false;
        }
        return i_tTaskData.isReceiveAward;
    }

    /// <summary>
    /// 领取任务奖励
    /// </summary>
    /// <param name="i_nTaskCfgId"></param>
    public void TaskReceiveAward(int i_nTaskCfgId)
    {
        TaskData taskData = this.GetTaskData(i_nTaskCfgId);
        if (taskData == null)
        {
            return;
        }

        if (!this.IsCompleted(taskData))
        {
            return;
        }

        if (this.IsReceiveAward(taskData))
        {
            return;
        }

        if (!m_pTaskCompleteRecord.ContainsKey(i_nTaskCfgId))
        {
            m_pTaskCompleteRecord.Add(i_nTaskCfgId, 0);
        }
        m_pTaskCompleteRecord[i_nTaskCfgId]++;

        taskData.isReceiveAward = true;

        Task_Data taskCfgData = ConfigManager.Task.Get(i_nTaskCfgId);

        if (taskCfgData.TaskAward.Length == 2)
        {
            this.GetSystem<GiftSystem>().ReceiveAward((AwardTypeEnum)taskCfgData.TaskAward[0], taskCfgData.TaskAward[1]);
        }

        Debug.Instance.Log($"TaskSystem TaskReceiveAward -> RoleId({this.GetPlayer().GetRoleId()}) TaskCfgId({i_nTaskCfgId})", LogType.system);

        if (taskCfgData.TaskEvent != (int)TaskEventEnum.eAccomplishTaskByType)
        {
            TriggerTaskEventAddValue(TaskEventEnum.eAccomplishTaskByType, 1, new List<int> { taskCfgData.TaskType });
        }
        if (taskCfgData.TaskEvent != (int)TaskEventEnum.eAccomplishTaskByEvent)
        {
            TriggerTaskEventAddValue(TaskEventEnum.eAccomplishTaskByEvent, 1, new List<int> { taskCfgData.TaskEvent });
        }

        bool isCompletedAllDailyTask = true;
        foreach (int taskCfgId in m_pTaskTypeMapping[TaskTypeEnum.eDailyTask])
        {
            TaskData dailyTaskDatas = GetTaskData(taskCfgId);
            if (!dailyTaskDatas.isReceiveAward)
            {
                isCompletedAllDailyTask = false;
                break;
            }
        }
        if (isCompletedAllDailyTask)
        {
            TriggerTaskEventAddValue(TaskEventEnum.eTaskEvent209, 1);
        }

        this.OnChangeData();
    }
}

/// <summary>
/// 任务数据
/// </summary>
public class TaskData
{
    /// <summary>
    /// 任务配置Id
    /// </summary>
    public int taskCfgId = 0;
    /// <summary>
    /// 任务当前数值
    /// </summary>
    public long taskValue = 0;
    /// <summary>
    /// 是否已领取奖励
    /// </summary>
    public bool isReceiveAward = false;
}