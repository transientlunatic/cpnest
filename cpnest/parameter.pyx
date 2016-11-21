from __future__ import division
import numpy as np
cimport numpy as np
from libc.math cimport log,exp,sqrt,cos,fabs,sin
cimport cython

cdef inline double log_add(double x, double y): return x+log(1.0+exp(y-x)) if x >= y else y+log(1.0+exp(x-y))

cdef class parameter:

    def __cinit__(self, str name, list bound):
        self.name = name
        self.bounds[0] = bound[0]
        self.bounds[1] = bound[1]
        self.value = np.random.uniform(self.bounds[0],self.bounds[1])

    def __str__(self):
        return 'parameter %s : %s in %s - %s' % (self.name,repr(self.value),repr(self.bounds[0]),repr(self.bounds[1]))

    cpdef inbounds(self):
        if self.value > self.bounds[1] or self.value < self.bounds[0]:
            return False
        return True

cdef class LivePoint:

    def __cinit__(self, list names, list bounds):
        self.logL = -np.inf
        self.logP = -np.inf
        self.names = names
        self.dimension = len(names)
        self.parameters = []
        cdef unsigned int i
        for i in range(self.dimension):
            self.parameters.append(parameter(names[i],bounds[i]))

    cpdef double get(self, str name):
        cdef unsigned int i
        for i in range(self.dimension):
            if self.parameters[i].name == name:
                return self.parameters[i].value

    cpdef void set(self, str name, double value):
        cdef unsigned int i
        for i in range(self.dimension):
            if self.parameters[i].name == name:
                self.parameters[i].value = value

cpdef void copy_live_point(LivePoint out_live, LivePoint in_live):
    """
    helper function to copy live points
    """
    cdef unsigned int i
    for i in range(in_live.dimension):
        out_live.parameters[i].value = np.copy(in_live.parameters[i].value)
    out_live.logL = np.copy(in_live.logL)
    out_live.logP = np.copy(in_live.logP)

cpdef double logPrior(list data, LivePoint x):
    cdef unsigned int i
    cdef double logP = 0.0
    for i in range(x.dimension):
        if not(x.parameters[i].inbounds()):
            logP = -np.inf
            return logP
    return logP

@cython.cdivision(True)
@cython.boundscheck(False)
cpdef double logLikelihood(list data, LivePoint x):
    """
    Likelihood function
    """
    if data is None:
        return 0.0
    cdef unsigned int i,j
    cdef unsigned int N = len(data)
    cdef double logL=0.0
    cdef double mean = x.get('mean')
    cdef double sigma = x.get('sigma')
    cdef double residuals
    for i in range(N):
        residuals = (data[i]-mean)/sigma
        logL += -0.5*residuals*residuals
    return logL

# optimisation test functions, see https://en.wikipedia.org/wiki/Test_functions_for_optimization

cdef double log_eggbox(double x, double y):
    cdef double tmp = 2.0+cos(x/2.)*cos(y/2.)
    return -5.0*log(tmp)

cdef double ackley(double x, double y):
    cdef double r = sqrt(0.5*(x*x+y*y))
    cdef double first = 20.0*exp(r)
    cdef double second = exp(0.5*(cos(2.0*np.pi*x)+cos(2.0*np.pi*y)))
    return -(first+second-exp(1)-20)

cdef double camel(double x, double y):
    cdef double x2 = x*x
    cdef double x4 = x2*x2
    cdef double x6 = x4*x2
    return -(2.0*x2-1.05*x4+x6/6.0+x*y+y*y)

cdef double bukin(double x, double y):
    return -(100.0*sqrt(fabs(y-0.01*x*x))+0.01*fabs(x+10.0))

cdef double cross_in_tray(double x, double y):
    return -(0.0001*(fabs(sin(x)*sin(y)*exp(fabs(100.0-sqrt(x*x+y*y)/np.pi)))+1)**0.1)

cdef double rosenbrock(double x, double y):
    return -(100.0*(y-x*x)*(y-x*x)+(x-1)*(x-1))

cdef double rastrigin(double x, double y):
    return -(20.0+(x*x-10.0*cos(2.0*np.pi*x))+(y*y-10.0*cos(2.0*np.pi*y)))