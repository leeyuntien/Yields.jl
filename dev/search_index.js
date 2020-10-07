var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Yields","category":"page"},{"location":"#Yields","page":"Home","title":"Yields","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Yields]","category":"page"},{"location":"#Yields.AbstractYield","page":"Home","title":"Yields.AbstractYield","text":"An AbstractYield is an object which can be called with:\n\nrate(yield,time) for the spot rate at a given time\ndiscount(yield,time) for the spot discount rate at a given time\n\n\n\n\n\n","category":"type"},{"location":"#Yields.Constant","page":"Home","title":"Yields.Constant","text":"Constant(rate)\n\nConstruct a yield object where the spot rate is constant for all maturities.\n\nExamples\n\njulia> y = Yields.Constant(0.05)\njulia> discount(y,2)\n0.9070294784580498     # 1 / (1.05) ^ 2\n\n\n\n\n\n","category":"type"},{"location":"#Yields.Step","page":"Home","title":"Yields.Step","text":"Step(rates,times)\n\nCreate a yield curve object where the applicable rate is the effective rate of interest applicable until corresponding time.\n\nExamples\n\njulia>y = Yields.Step([0.02,0.05], [1,2])\n\njulia>rate(y,0.5)\n0.02\n\njulia>rate(y,1.5)\n0.05\n\njulia>rate(y,2.5)\n0.05\n\n\n\n\n\n","category":"type"},{"location":"#Base.:+-Tuple{Yields.AbstractYield,Yields.AbstractYield}","page":"Home","title":"Base.:+","text":"Yields.AbstractYield + Yields.AbstractYield\n\nThe addition of two yields will create a RateCombination. For rate, discount, and accumulation purposes the spot rates of the two curves will be added together.\n\n\n\n\n\n","category":"method"},{"location":"#Base.:--Tuple{Yields.AbstractYield,Yields.AbstractYield}","page":"Home","title":"Base.:-","text":"Yields.AbstractYield - Yields.AbstractYield\n\nThe subtraction of two yields will create a RateCombination. For rate, discount, and accumulation purposes the spot rates of the second curves will be subtracted from the first.\n\n\n\n\n\n","category":"method"},{"location":"#Base.accumulate-Union{Tuple{T}, Tuple{T,Any,Any}} where T<:Yields.AbstractYield","page":"Home","title":"Base.accumulate","text":"accumulate(yield,from,to)\n\nThe accumulation factor for the yield from time from through to.\n\n\n\n\n\n","category":"method"},{"location":"#Base.accumulate-Union{Tuple{T}, Tuple{T,Any}} where T<:Yields.AbstractYield","page":"Home","title":"Base.accumulate","text":"accumulate(yield,time)\n\nThe accumulation factor for the yield from time zero through time.\n\n\n\n\n\n","category":"method"},{"location":"#Yields.Forward-Tuple{Any}","page":"Home","title":"Yields.Forward","text":"Forward(rate_vector)\n\nTakes a vector of 1-period forward rates and constructs a discount curve.\n\n\n\n\n\n","category":"method"},{"location":"#Yields.Par-Tuple{Any,Any}","page":"Home","title":"Yields.Par","text":"Construct a curve given a set of bond yields priced at par with a single coupon per period.\n\n\n\n\n\n","category":"method"},{"location":"#Yields.discount-Tuple{Any,Any,Any}","page":"Home","title":"Yields.discount","text":"discount(yield,from,to)\n\nThe discount factor for the yield from time from through to.\n\n\n\n\n\n","category":"method"},{"location":"#Yields.discount-Tuple{Any,Any}","page":"Home","title":"Yields.discount","text":"discount(yield,time)\n\nThe discount factor for the yield from time zero through time.\n\n\n\n\n\n","category":"method"},{"location":"#Yields.rate-Tuple{Any,Any}","page":"Home","title":"Yields.rate","text":"rate(yield,time)\n\nThe spot rate at time for the given yield.\n\n\n\n\n\n","category":"method"}]
}
