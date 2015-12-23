void dummyTask(int arg){}

SchedTask tasks[_numTasks];

void initTasks()
{
  for (int i=0;i<_numTasks;i++)
  {
    scheduleTask(i,dummyTask, 0.25, 0);
    clearTask(i);
  }
}

void scheduleTask(int taskID, schTask task, float hz, int arg)
{
  if ((taskID >= 0) && (taskID < _numTasks))
  {
    tasks[taskID].init(task, hz, arg);
  }
}

void clearTask(int taskID)
{
  tasks[taskID].clear();
}

void checkTasks()
{
  for (int i=0;i<_numTasks;i++)
  {
     tasks[i].check(micros());
  } 
}
