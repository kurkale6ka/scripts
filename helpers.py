# from helpers import ls
def ls(obj):
   for member in dir(obj):
      if not '__' in member:
         print(member)
