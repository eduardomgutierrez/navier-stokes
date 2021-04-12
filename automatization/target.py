class Target():
  """ stat_collectors: list of tuples (GROUP, [NAMES])"""
  def __init__(self, name, comp = None, evars=[], flags=[], stats_collectors= None):
    
    if(not name.startswith('T_')):
      raise Exception('Target\'s name\'s must start with: T_')
      
    self.name  = name.strip()
    self.evars = evars
    self.flags = flags
    self.comp  = comp
    self.stats_collectors = stats_collectors

  # SP [MFLOP/s]  1.0E-06*(PMC0*4.0+PMC1+PMC2*8.0)/time

