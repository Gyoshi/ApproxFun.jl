

## Converison

#ensure that COnversion is called
coefficients{DD}(cfs::Vector,A::Fourier{DD},B::Laurent{DD})=(Conversion(A,B)*cfs).coefficients
coefficients{DD}(cfs::Vector,A::Laurent{DD},B::Fourier{DD})=(Conversion(A,B)*cfs).coefficients

hasconversion{DD}(::Fourier{DD},::Laurent{DD})=true
hasconversion{DD}(::Laurent{DD},::Fourier{DD})=true

Conversion{DD}(a::Laurent{DD},b::Fourier{DD})=ConcreteConversion(a,b)
Conversion{DD}(a::Fourier{DD},b::Laurent{DD})=ConcreteConversion(a,b)

function getindex{DD,T}(C::ConcreteConversion{Laurent{DD},Fourier{DD},T},k::Integer,j::Integer)
    if k==j==1
        one(T)
    elseif iseven(k) && k==j
        -one(T)*im
    elseif iseven(k) && k+1==j
        one(T)*im
    elseif isodd(k) && (k==j || k-1==j )
        one(T)
    else
        zero(T)
    end
end


function getindex{DD,T}(C::ConcreteConversion{Fourier{DD},Laurent{DD},T},k::Integer,j::Integer)
    if k==j==1
        one(T)
    elseif iseven(k) && k==j
        one(T)/2*im
    elseif iseven(k) && k+1==j
        one(T)/2
    elseif isodd(k) && k==j
        one(T)/2
    elseif isodd(k) && j==k-1
        -one(T)*im/2
    else
        zero(T)
    end
end


bandinds{DD}(::ConcreteConversion{Laurent{DD},Fourier{DD}})=-1,1
bandinds{DD}(::ConcreteConversion{Fourier{DD},Laurent{DD}})=-1,1

for RULE in (:conversion_rule,:maxspace_rule,:union_rule)
    @eval function $RULE{DD}(A::Laurent{DD},B::Fourier{DD})
        @assert domainscompatible(A,B)
        B
    end
end

conversion_type{DD<:Circle}(A::Fourier{DD},B::Fourier{DD})=domain(A).orientation?A:B

hasconversion{DD}(A::Fourier{DD},B::Fourier{DD})=domain(A) == reverse(domain(B))
function Conversion{DD}(A::Fourier{DD},B::Fourier{DD})
    if A==B
        ConversionWrapper(eye(A))
    else
        @assert domain(A) == reverse(domain(B))
        ConcreteConversion(A,B)
    end
end
bandinds{DD}(::ConcreteConversion{Fourier{DD},Fourier{DD}})=0,0

getindex{DD,T}(C::ConcreteConversion{Fourier{DD},Fourier{DD},T},k::Integer,j::Integer) =
    k==j?(iseven(k)?(-one(T)):one(T)):zero(T)





### Cos/Sine


function Derivative(S::Union{CosSpace,SinSpace},order)
    @assert isa(domain(S),PeriodicInterval)
    ConcreteDerivative(S,order)
end


bandinds{CS<:CosSpace}(D::ConcreteDerivative{CS})=iseven(D.order)?(0,0):(0,1)
bandinds{S<:SinSpace}(D::ConcreteDerivative{S})=iseven(D.order)?(0,0):(-1,0)
rangespace{S<:CosSpace}(D::ConcreteDerivative{S})=iseven(D.order)?D.space:SinSpace(domain(D))
rangespace{S<:SinSpace}(D::ConcreteDerivative{S})=iseven(D.order)?D.space:CosSpace(domain(D))


function getindex{CS<:CosSpace,OT,T}(D::ConcreteDerivative{CS,OT,T},k::Integer,j::Integer)
    d=domain(D)
    m=D.order
    C=T(2/(d.b-d.a)*π)

    if k==j && mod(m,4)==0
        (C*(k-1))^m
    elseif k==j && mod(m,4)==2
        -(C*(k-1))^m
    elseif j==k+1 && mod(m,4)==1
        -(C*k)^m
    elseif j==k+1 && mod(m,4)==3
        (C*k)^m
    else
        zero(T)
    end
end

function getindex{CS<:SinSpace,OT,T}(D::ConcreteDerivative{CS,OT,T},k::Integer,j::Integer)
    d=domain(D)
    m=D.order
    C=T(2/(d.b-d.a)*π)

    if k==j && mod(m,4)==0
        (C*k)^m
    elseif k==j && mod(m,4)==2
        -(C*k)^m
    elseif j==k-1 && mod(m,4)==1
        (C*j)^m
    elseif j==k-1 && mod(m,4)==3
        -(C*j)^m
    else
        zero(T)
    end
end

Integral(::CosSpace,m::Integer)=error("Integral not defined for CosSpace.  Use Integral(SliceSpace(CosSpace(),1)) if first coefficient vanishes.")


bandinds{CS<:SinSpace}(D::ConcreteIntegral{CS})=iseven(D.order)?(0,0):(-1,0)
rangespace{S<:CosSpace}(D::ConcreteIntegral{S})=iseven(D.order)?D.space:SinSpace(domain(D))
rangespace{S<:SinSpace}(D::ConcreteIntegral{S})=iseven(D.order)?D.space:CosSpace(domain(D))

function getindex{CS<:SinSpace,OT,T}(D::ConcreteIntegral{CS,OT,T},k::Integer,j::Integer)
    d=domain(D)
    @assert isa(d,PeriodicInterval)
    m=D.order
    C=T(2/(d.b-d.a)*π)


    if k==j && mod(m,4)==0
        (C*k)^(-m)
    elseif k==j && mod(m,4)==2
        -(C*k)^(-m)
    elseif j==k-1 && mod(m,4)==1
        -(C*j)^(-m)
    elseif j==k-1 && mod(m,4)==3
        (C*j)^(-m)
    else
        zero(T)
    end
end

function Integral{T,CS<:CosSpace,DD<:PeriodicInterval}(S::SliceSpace{1,1,CS,T,DD,1},k::Integer)
    @assert isa(d,PeriodicInterval)
    ConcreteIntegral(S,k)
end

bandinds{T,CS<:CosSpace,DD<:PeriodicInterval}(D::ConcreteIntegral{SliceSpace{1,1,CS,T,DD,1}})=(0,0)
rangespace{T,CS<:CosSpace,DD<:PeriodicInterval}(D::ConcreteIntegral{SliceSpace{1,1,CS,T,DD,1}})=iseven(D.order)?D.space:SinSpace(domain(D))

function getindex{T,CS<:CosSpace,DD<:PeriodicInterval}(D::ConcreteIntegral{SliceSpace{1,1,CS,T,DD,1}},k::Integer,j::Integer)
    d=domain(D)
    m=D.order
    C=T(2/(d.b-d.a)*π)


    if k==j
        if mod(m,4)==0
            (C*k)^(-m)
        elseif mod(m,4)==2
            -(C*k)^(-m)
        elseif mod(m,4)==1
        (C*k)^(-m)
        else   # mod(m,4)==3
            -(C*k)^(-m)
        end
    else
        zero(T)
    end
end

# CosSpace Multiplicaiton is the same as Chebyshev


Multiplication{CS<:CosSpace}(f::Fun{CS},sp::CS) = ConcreteMultiplication(f,sp)
Multiplication{CS<:SinSpace}(f::Fun{CS},sp::CS) = ConcreteMultiplication(f,sp)
Multiplication{CS<:CosSpace}(f::Fun{CS},sp::SinSpace) = ConcreteMultiplication(f,sp)
Multiplication{CS<:SinSpace}(f::Fun{CS},sp::CosSpace) = ConcreteMultiplication(f,sp)

bandinds{Sp<:CosSpace}(M::ConcreteMultiplication{Sp,Sp}) =
    (1-length(M.f.coefficients),length(M.f.coefficients)-1)
rangespace{Sp<:CosSpace}(M::ConcreteMultiplication{Sp,Sp}) = domainspace(M)
getindex{Sp<:CosSpace}(M::ConcreteMultiplication{Sp,Sp},k::Integer,j::Integer) =
    chebmult_getindex(M.f.coefficients,k,j)



function getindex{Sp<:SinSpace}(M::ConcreteMultiplication{Sp,Sp},k::Integer,j::Integer)
    a=M.f.coefficients
    ret=0.5*toeplitz_getindex([0.;-a],k,j)
    if k ≥ 2
        ret+=0.5*hankel_getindex(a,k,j)
    end
    ret
end

bandinds{Sp<:SinSpace}(M::ConcreteMultiplication{Sp,Sp})=-length(M.f)-1,length(M.f)-1
rangespace{Sp<:SinSpace}(M::ConcreteMultiplication{Sp,Sp})=CosSpace(domain(M))


function getindex{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Sp,Cs},k::Integer,j::Integer)
    a=M.f.coefficients
    0.5*toeplitz_getindex(a[2:end],[a[1];0.;-a],k,j) +
        0.5*hankel_getindex(a,k,j)
end

bandinds{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Sp,Cs})=1-length(M.f),length(M.f)+1
rangespace{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Sp,Cs})=SinSpace(domain(M))



function getindex{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Cs,Sp},k::Integer,j::Integer)
    a=M.f.coefficients
    0.5*toeplitz_getindex(a,k,j)
    if length(a)>=3
        -0.5*hankel_getindex(slice(a,3:length(a)),k,j)
    end
    A
end

bandinds{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Cs,Sp})=(1-length(M.f.coefficients),length(M.f.coefficients)-1)
rangespace{Sp<:SinSpace,Cs<:CosSpace}(M::ConcreteMultiplication{Cs,Sp})=SinSpace(domain(M))



function Multiplication{T,D}(a::Fun{Fourier{D},T},sp::Fourier{D})
    d=domain(a)
    c,s=vec(a)
    O=BandedOperator{T}[Multiplication(c,CosSpace(d)) Multiplication(s,SinSpace(d));
                        Multiplication(s,CosSpace(d)) Multiplication(c,SinSpace(d))]
    MultiplicationWrapper(a,SpaceOperator(InterlaceOperator(O),space(a),sp))
end


## Definite integral

DefiniteIntegral{D<:PeriodicInterval}(sp::Fourier{D})=DefiniteIntegral{typeof(sp),Float64}(sp)
DefiniteIntegral{D<:Circle}(sp::Fourier{D})=DefiniteIntegral{typeof(sp),Complex{Float64}}(sp)

function getindex{T,D}(Σ::DefiniteIntegral{Fourier{D},T},kr::Range)
    d = domain(Σ)
    if isa(d,PeriodicInterval)
        T[k == 1?  d.b-d.a : zero(T) for k=kr]
    else
        @assert isa(d,Circle)
        T[k == 2?  -d.radius*π : (k==3?d.radius*π*im :zero(T)) for k=kr]
    end
end

datalength{D}(Σ::DefiniteIntegral{Fourier{D}})=isa(domain(Σ),PeriodicInterval)?1:3

DefiniteLineIntegral{D}(sp::Fourier{D})=DefiniteLineIntegral{typeof(sp),Float64}(sp)

function getindex{T,D}(Σ::DefiniteLineIntegral{Fourier{D},T},kr::Range)
    d = domain(Σ)
    if isa(d,PeriodicInterval)
        T[k == 1?  d.b-d.a : zero(T) for k=kr]
    else
        @assert isa(d,Circle)
        T[k == 1?  2d.radius*π : zero(T) for k=kr]
    end
end

datalength{D}(Σ::DefiniteLineIntegral{Fourier{D}})=1


transformtimes{CS<:CosSpace,D}(f::Fun{CS},g::Fun{Fourier{D}}) = transformtimes(Fun(interlace(f.coefficients,zeros(eltype(f),length(f)-1)),Fourier(domain(f))),g)
transformtimes{SS<:SinSpace,D}(f::Fun{SS},g::Fun{Fourier{D}}) = transformtimes(Fun(interlace(zeros(eltype(f),length(f)+1),f.coefficients),Fourier(domain(f))),g)
transformtimes{CS<:CosSpace,SS<:SinSpace}(f::Fun{CS},g::Fun{SS}) = transformtimes(Fun(interlace(f.coefficients,zeros(eltype(f),length(f)-1)),Fourier(domain(f))),Fun(interlace(zeros(eltype(g),length(g)+1),g.coefficients),Fourier(domain(g))))
transformtimes{CS<:CosSpace,D}(f::Fun{Fourier{D}},g::Fun{CS}) = transformtimes(g,f)
transformtimes{SS<:SinSpace,D}(f::Fun{Fourier{D}},g::Fun{SS}) = transformtimes(g,f)
transformtimes{SS<:SinSpace,CS<:CosSpace}(f::Fun{SS},g::Fun{CS}) = transformtimes(g,f)
