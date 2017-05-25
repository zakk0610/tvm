from ..runtime_ctypes import TVMArrayHandle

cdef class NDArrayBase:
    cdef DLTensor* chandle
    cdef int c_is_view

    cdef inline _set_handle(self, handle):
        cdef unsigned long long ptr
        if handle is None:
            self.chandle = NULL
        else:
            ptr = ctypes.cast(handle, ctypes.c_void_p).value
            self.chandle = <DLTensor*>(ptr)

    property _dltensor_addr:
        def __get__(self):
            return <unsigned long long>self.chandle

    property handle:
        def __get__(self):
            if self.chandle == NULL:
                return None
            else:
                return ctypes.cast(
                    <unsigned long long>self.chandle, TVMArrayHandle)

        def __set__(self, value):
            self._set_handle(value)

    def __init__(self, handle, is_view):
        self._set_handle(handle)
        self.c_is_view = is_view

    def __dealloc__(self):
        if self.c_is_view == 0:
            CALL(TVMArrayFree(self.chandle))


cdef c_make_array(void* chandle, is_view):
    ret = _CLASS_NDARRAY(None, is_view)
    (<NDArrayBase>ret).chandle = <DLTensor*>chandle
    return ret

cdef _DLTENSOR_COMPATS = ()

def _reg_dltensor(cls):
    global _DLTENSOR_COMPATS
    _DLTENSOR_COMPATS += (cls,)

def _make_array(handle, is_view):
    cdef unsigned long long ptr
    ptr = ctypes.cast(handle, ctypes.c_void_p).value
    return c_make_array(<void*>ptr, is_view)

cdef object _CLASS_NDARRAY = None

def _set_class_ndarray(cls):
    global _CLASS_NDARRAY
    _CLASS_NDARRAY = cls