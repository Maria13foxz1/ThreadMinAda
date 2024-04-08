with Ada.Text_IO; use Ada.Text_IO;
with ada.numerics.discrete_random;

procedure Threadminada is

   count_array : integer := 100_000;
   thread_num : constant integer := 7;
   minIdx : Integer;

   array_work : array(1..count_array) of integer;

   procedure Init_Array is
   type randRange is new Integer range 1..count_array;
   package Rand_Int is new ada.Numerics.Discrete_Random(randRange);
   use Rand_Int;
   generics : Generator;
   number: randRange;
   begin
      for i in 1..(count_array) loop
         Reset(generics);
         number:= random(generics);
         array_work(i) := Integer(number);
      end loop;
      array_work(count_array/56):=-5;
   end Init_Array;

   function part_min(start_idx, end_idx: in Integer) return Integer is
      min : Integer := start_idx;
   begin
      for i in start_idx..end_idx loop
         if array_work(i) <array_work(min) then
            min := i;
           end if;
      end loop;

      return min;
   end part_min;

   task type working_thread is
      entry Start(start_idx, end_idx: in Integer);
   end working_thread;

   --protected modol--
   protected monitor is
      procedure set_part_min(min:in Integer);
      entry get_min(min : out Integer);
   private
      task_count : Integer := 0;
      current_minimum : Integer:=1;
   end monitor;

   protected body monitor is
      procedure set_part_min(min : in Integer) is
      begin
         if array_work(current_minimum) > array_work(min) then
            current_minimum := min;
         end if;
         task_count := task_count +1;
      end set_part_min;

      entry get_min(min : out Integer) when task_count = thread_num is
      begin
         min := current_minimum;
         end get_min;
      end monitor;

   task body working_thread is
      min :Integer;
      start_idx, end_idx : Integer;
   begin
      accept Start (start_idx : in Integer; end_idx : in Integer) do
         working_thread.start_idx := start_idx;
         working_thread.end_idx := end_idx;
      end Start;
      min := part_min(start_idx, end_idx);
      monitor.set_part_min(min);
   end working_thread;

   function get_min_parallel return Integer is
      min : Integer;
      threads : array(1..thread_num) of working_thread;
   begin
      for i in 1..thread_num loop
         threads(i).Start(start_idx => (i-1) * count_array / thread_num + 1,
                          end_idx => i * count_array / thread_num);
      end loop;

      monitor.get_min(min);
      return min;
      end get_min_parallel;

begin
   Init_Array;
   --Put_Line(arr(part_min(1, length))'img);
   minIdx := get_min_parallel;
   Put_Line("The minimal number "&array_work(minIdx)'img&" in index"&minIdx'img);
end Threadminada;
