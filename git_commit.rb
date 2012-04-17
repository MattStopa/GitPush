class Commit
  attr_accessor :inserts, :deletes, :amount, :net

  def initialize
    self.inserts = 0
    self.deletes = 0
    self.amount = 0
  end

  def total
    inserts + deletes
  end

  def update_commits(inserts, deletes)
    self.inserts += inserts
    self.deletes += deletes
    self.amount += 1
  end

  def net
    inserts - deletes
  end
end