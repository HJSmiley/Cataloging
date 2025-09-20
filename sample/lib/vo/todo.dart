class Todo{
  int userId;
  int id;
  String title;
  bool completed;

  Todo({
    this.title='',
    this.completed=false,
    this.userId=0,
    this.id=0
  });

  factory Todo.fromJson(Map<String, dynamic> json){
    return Todo(
        title: json['title'],
        id: json['id'],
        completed: json['completed'],
        userId:json['userId']
    );
  }
}