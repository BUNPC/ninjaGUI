function d = NN22_interpNAN( d )

lst1 = find(isnan(d(2:end)) & ~isnan(d(1:end-1))) + 1;
lst2 = find(isnan(d(1:end-1)) & ~isnan(d(2:end)));

while ~isempty(lst1) | ~isempty(lst2)

    d(lst1) = d(lst1-1);
    d(lst2) = d(lst2+1);

    lst1 = find(isnan(d(2:end)) & ~isnan(d(1:end-1))) + 1;
    lst2 = find(isnan(d(1:end-1)) & ~isnan(d(2:end)));

end
